#!/bin/bash

usage="$(basename "$0") [-z ZONE] [-o OUTPUT_DIR] [-h]

Recovers the JMeter reports creating a new temporary compute instance,
attaching the JMeter disks, downloading the files and then deleting
the compute instance.

where:
    -z  set the ZONE (default: us-central1-a)
    -o  output directory (default: .)
    -h  show this help text"

zone="us-central1-a"
output_dir="."

while getopts ':hz:' option; do
  case "$option" in
    z) zone=$OPTARG
       ;;
    o) output_dir=$OPTARG
       ;;
    h|*) echo "$usage"
       exit
       ;;
  esac
done
shift "$((OPTIND - 1))"

echo "Creating jmeter instance"
gcloud compute instances create jmeter-instance --zone=${zone}

echo "Attaching disks"
gcloud compute instances attach-disk jmeter-instance --disk=jmeter-sync --zone=${zone}
gcloud compute instances attach-disk jmeter-instance --disk=jmeter-async --zone=${zone}

echo "Compacting report files"
gcloud compute ssh --zone=${zone} jmeter-instance -- '\
sudo mkdir /mnt/sync /mnt/async && \
sudo mount /dev/sdb /mnt/sync && \
sudo mount /dev/sdc /mnt/async && \
cd /mnt/sync/sync && \
sudo tar -czf sync.tar.gz report/ results.csv && \
cd /mnt/async/async && \
sudo tar -czf async.tar.gz report/ results.csv'

echo "Downling reports..."
gcloud compute scp jmeter-instance:/mnt/sync/sync/sync.tar.gz ${output_dir}
gcloud compute scp jmeter-instance:/mnt/async/async/async.tar.gz ${output_dir}

echo "Removing report files from the server"
gcloud compute ssh --zone=${zone} jmeter-instance -- 'sudo rm -rf /mnt/sync/sync /mnt/async/async'

echo "Deleting instance"
gcloud compute instances delete jmeter-instance --quiet
