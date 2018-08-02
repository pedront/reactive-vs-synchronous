#!/bin/bash

basedir=$(dirname -- "$0")

source ${basedir}/config.sh


source ${basedir}/build_deploy_images.sh

message_if_error "Error building and deploying images...exiting."


source ${basedir}/create_containers.sh -z ${zone}

message_if_error "Error creating cluster...exiting."


source ${basedir}/create_bucket.sh

message_if_error "Error creating bucket...exiting."


source ${basedir}/kubernetes_sync.sh -z ${zone}

message_if_error  "Error creating synchronous servers...exiting."


source ${basedir}/kubernetes_async.sh -z ${zone}

message_if_error  "Error creating reactive servers...exiting."


echo "Waiting 60s for instances to settle"
for i in {60..10..10}
do
  echo -ne $i"s "\\r
  sleep 10s
done

source ${basedir}/kubernetes_jmeter.sh -z ${zone}

echo "Downloading report files"
#source ${basedir}/get_jmeter_reports.sh -z ${zone}

echo "Finished"
