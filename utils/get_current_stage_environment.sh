#!/bin/bash

# Parameters
PROD_SERVICE_NAME="$1"

# Constants
ANNOTATION="pipelines.jfrog.com/environment"
BLUE="blue"
GREEN="green"

check_service_exists() {
  service=$(kubectl get service $PROD_SERVICE_NAME 2>&1)
  result=$?
  if [[ $result == 0 ]]; then
    echo true
  else
    echo false
  fi
}

fetch_service_yaml() {
  tmp_dir=$(mktemp -d -t pipelines-XXXXXXXXXX)
  kubectl get service $PROD_SERVICE_NAME -o yaml > $tmp_dir/service.yml
  echo $tmp_dir/service.yml
}

get_annotation_value() {
  file_path=$1
  annotation_path=.metadata.annotations.\"$2\"
  yq -r $annotation_path $file_path
}

main() {
  exists=$(check_service_exists $PROD_SERVICE_NAME)
  if [[ $exists != true ]]; then
    # If prod service does not exist start with blue environment
    echo $BLUE
    return
  fi

  yaml_path=$(fetch_service_yaml $PROD_SERVICE_NAME)
  env=$(get_annotation_value $yaml_path $ANNOTATION)

  if [[ $env == "null" ]]; then
    env=$BLUE
  fi

  echo $env
}

main $@


