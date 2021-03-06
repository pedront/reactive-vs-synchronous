#!/bin/bash

basedir=$(dirname -- "$0")

source ${basedir}/utils.sh


usage="$(basename "$0") [-c CLUSTER-NAME] [-z ZONE] [-h]

Creates the deployments and services to run the reactive server.

where:
    -c  set the CLUSTER-NAME (default: async)
    -z  set the ZONE (default: us-central1-a)
    -h  show this help text"

cluster_name=async
zone=us-central1-a

while getopts ':hc:z:' option; do
  case "$option" in
    c) cluster_name=$OPTARG
       ;;
    z) zone=$OPTARG
       ;;
    h|*) echo "$usage"
       exit
       ;;
  esac
done
shift "$((OPTIND - 1))"


echo "Loading env variables"
source ${basedir}/config.properties


has_async_container=$(gcloud container clusters list --zone=${zone} --format="get(name)" \
  --filter="name=${container_async}")
if [ -z "${has_async_container}" ]
then
  echo "Reactive container doesn't exists...exiting."

  exit 1
fi


echo "Getting auth for the reactive cluster"
gcloud container clusters get-credentials ${container_async} --zone=${zone}

message_if_error "Error getting auth...exiting."


has_dep_back_async=$(kubectl get deployments --field-selector='metadata.name=${app_backend_async}' \
  -o jsonpath='{.items[*].metadata.name}')
if [ -z "${has_dep_back_async}" ]
then
  echo "Creating reactive backend deployment"
  cat ${basedir}/../kubernetes/deployment/backend.yml | \
    sed "s/%%APP_BACKEND%%/${app_backend_async}/" | \
    sed "s#%%IMAGE_PREFIX%%#${image_prefix}#" | \
    sed "s/%%IMAGE_NAME%%/${project_backend}/" | \
    sed "s/%%IMAGE_TAG%%/${docker_tag}/" | \
    kubectl create -f -

  message_if_error  "Error creating reactive backend...exiting."
else
  echo "Reactive backend deployment already exists."
fi


has_dep_svc_back_async=$(kubectl get services --field-selector='metadata.name=${app_backend_async}' \
  -o jsonpath='{.items[*].metadata.name}')
if [ -z "${has_dep_svc_back_async}" ]
then
  echo "Creating service for reactive backend"
  cat ${basedir}/../kubernetes/service/backend.yml | \
    sed "s/%%APP_BACKEND%%/${app_backend_async}/" | \
    kubectl create -f -

  message_if_error  "Error creating service...exiting."
else
  echo "Service for reactive backend already exists"
fi


has_dep_server_async=$(kubectl get deployments --field-selector='metadata.name=${app_server_async}' \
  -o jsonpath='{.items[*].metadata.name}')
if [ -z "${has_dep_server_async}" ]
then
  echo "Creating reactive server deployment"
  cat ${basedir}/../kubernetes/deployment/server.yml | \
    sed "s/%%APP_SERVER%%/${app_server_async}/" | \
    sed "s/%%APP_BACKEND%%/${app_backend_async}/" | \
    sed "s#%%IMAGE_PREFIX%%#${image_prefix}#" | \
    sed "s/%%IMAGE_NAME%%/${project_async}/" | \
    sed "s/%%IMAGE_TAG%%/${docker_tag}/" | \
    kubectl create -f -

  message_if_error  "Error creating reactive server...exiting."
else
  echo "Reactive server deployment already exists."
fi


has_dep_svc_server_async=$(kubectl get services --field-selector='metadata.name=${app_server_async}' \
  -o jsonpath='{.items[*].metadata.name}')
if [ -z "${has_dep_svc_server_async}" ]
then
  echo "Creating service for the reactive server"
  cat ${basedir}/../kubernetes/service/server.yml | \
    sed "s/%%APP_SERVER%%/${app_server_async}/" | \
    kubectl create -f -

  message_if_error  "Error creating service...exiting."
else
  echo "Service for the reactive server already exists."
fi


get_service_external_ip server-async SERVER_ASYNC_IP

echo "Reactive server external IP: ${SERVER_ASYNC_IP}"
