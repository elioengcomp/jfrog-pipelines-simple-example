#!/bin/bash

#!/bin/bash

# Constants
ANNOTATION="pipelines.jfrog.com/environment"
BLUE="blue"
GREEN="green"

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/util.sh
YQ_PATH=$SCRIPT_DIR/yq

cleanup_yaml() {
  file_path=$1
  $YQ_PATH eval -i 'del(.spec.clusterIP)' $file_path
  $YQ_PATH eval -i 'del(.spec.ports[].nodePort)' $file_path
  $YQ_PATH eval -i 'del(.metadata.annotations."meta.helm.sh/release-name")' $file_path
  $YQ_PATH eval -i 'del(.metadata.annotations."meta.helm.sh/release-namespace")' $file_path
  $YQ_PATH eval -i 'del(.metadata.labels."helm.sh/chart")' $file_path
  $YQ_PATH eval -i 'del(.status)' $file_path
}

set_fields() {
  file_path=$1
  name=$2
  env=$3
  $YQ_PATH eval -i ".metadata.name = \"$name\"" $file_path
  $YQ_PATH eval -i ".metadata.annotations.\"pipelines.jfrog.com/environment\" = \"$env\"" $file_path
  $YQ_PATH eval -i ".metadata.labels.\"app.kubernetes.io/managed-by\" = \"Pipelines\"" $file_path
}

copy_immutable_fields() {
  source_path=$1
  target_path=$2

  clusterIP=$($YQ_PATH eval ".spec.clusterIP" $source_path)
  $YQ_PATH eval -i ".spec.clusterIP = \"$clusterIP\"" $target_path
  nodePort=$($YQ_PATH eval ".spec.ports[0].nodePort" $source_path)
  $YQ_PATH eval -i ".spec.ports[0].nodePort = $nodePort" $target_path
  uid=$($YQ_PATH eval ".metadata.uid" $source_path)
  $YQ_PATH eval -i ".metadata.uid = \"$uid\"" $target_path
  resourceVersion=$($YQ_PATH eval ".metadata.resourceVersion" $source_path)
  $YQ_PATH eval -i ".metadata.resourceVersion = \"$resourceVersion\"" $target_path
}

main() {

  # Parameters
  SOURCE_SERVICE_NAME="$1"
  TARGET_SERVICE_NAME="$2"
  ENV_LABEL="$3"
  NAMESPACE="$4"

  echo "Copying service $SOURCE_SERVICE_NAME to $TARGET_SERVICE_NAME"

  source_yaml_path=$(fetch_service_yaml $SOURCE_SERVICE_NAME $NAMESPACE)

  target_exists=$(check_service_exists $TARGET_SERVICE_NAME $NAMESPACE)
  if [[ $target_exists == true ]]; then
    existing_target_yaml_path=$(fetch_service_yaml $TARGET_SERVICE_NAME $NAMESPACE)
    target_yaml_path=$(create_temporary_service_yaml_copy $source_yaml_path)
    cleanup_yaml $target_yaml_path
    copy_immutable_fields $existing_target_yaml_path $target_yaml_path
  else
    target_yaml_path=$(create_temporary_service_yaml_copy $source_yaml_path)
    cleanup_yaml $target_yaml_path
  fi

  set_fields $target_yaml_path $TARGET_SERVICE_NAME $ENV_LABEL
  kubectl apply -n $NAMESPACE -f $target_yaml_path
}

main $@

