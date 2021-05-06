#!/bin/bash

# Constants
ANNOTATION="pipelines.jfrog.com/environment"
BLUE="blue"
GREEN="green"

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/util.sh

cleanup_json() {
  file_path=$1
  jq 'del(.spec.clusterIP)' $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
  jq 'del(.spec.ports[].nodePort)' $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
  jq 'del(.metadata.annotations."meta.helm.sh/release-name")' $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
  jq 'del(.metadata.annotations."meta.helm.sh/release-namespace")' $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
  jq 'del(.metadata.labels."helm.sh/chart")' $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
  jq 'del(.status)' $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
}

set_fields() {
  file_path=$1
  name=$2
  env=$3
  jq ".metadata.name = \"$name\"" $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
  jq ".metadata.annotations.\"pipelines.jfrog.com/environment\" = \"$env\"" $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
  jq ".metadata.labels.\"app.kubernetes.io/managed-by\" = \"Pipelines\"" $file_path > $file_path.tmp && mv ${file_path}.tmp $file_path
}

copy_immutable_fields() {
  source_path=$1
  target_path=$2

  clusterIP=$(jq -r ".spec.clusterIP" $source_path)
  if [[ $? != 0 ]]; then
    exit $?
  fi
  jq ".spec.clusterIP = \"$clusterIP\"" $target_path > ${target_path}.tmp && mv ${target_path}.tmp $target_path

  nodePort=$(jq -r ".spec.ports[0].nodePort" $source_path)
  if [[ $? != 0 ]]; then
    exit $?
  fi
  jq ".spec.ports[0].nodePort = $nodePort" $target_path > ${target_path}.tmp && mv ${target_path}.tmp $target_path

  uid=$(jq -r ".metadata.uid" $source_path)
  if [[ $? != 0 ]]; then
    exit $?
  fi
  jq ".metadata.uid = \"$uid\"" $target_path > ${target_path}.tmp && mv ${target_path}.tmp $target_path

  resourceVersion=$(jq -r ".metadata.resourceVersion" $source_path)
  if [[ $? != 0 ]]; then
    exit $?
  fi
  jq ".metadata.resourceVersion = \"$resourceVersion\"" $target_path > ${target_path}.tmp && mv ${target_path}.tmp $target_path
}

main() {

  # Parameters
  SOURCE_SERVICE_NAME="$1"
  TARGET_SERVICE_NAME="$2"
  ENV_LABEL="$3"
  NAMESPACE="$4"

  echo "Copying service $SOURCE_SERVICE_NAME to $TARGET_SERVICE_NAME"

  source_json_path=$(fetch_service_json $SOURCE_SERVICE_NAME $NAMESPACE)
  target_exists=$(check_service_exists $TARGET_SERVICE_NAME $NAMESPACE)
  if [[ $target_exists == true ]]; then
    echo "Updating service $TARGET_SERVICE_NAME"
    existing_target_json_path=$(fetch_service_json $TARGET_SERVICE_NAME $NAMESPACE)
    target_json_path=$(create_temporary_service_json_copy $source_json_path)
    cleanup_json $target_json_path
    copy_immutable_fields $existing_target_json_path $target_json_path
  else
    echo "Creating service $TARGET_SERVICE_NAME"
    target_json_path=$(create_temporary_service_json_copy $source_json_path)
    cleanup_json $target_json_path
  fi

  set_fields $target_json_path $TARGET_SERVICE_NAME $ENV_LABEL
  kubectl apply -n $NAMESPACE -f $target_json_path
  if [[ $? != 0 ]]; then
    exit $?
  fi
}

main $@

