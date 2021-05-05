#!/bin/bash

# Constants
ANNOTATION="pipelines.jfrog.com/environment"
BLUE="blue"
GREEN="green"

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/util.sh

main() {

  # Parameters
  PROD_SERVICE_NAME="$1"
  NAMESPACE="$2"

  exists=$(check_service_exists $PROD_SERVICE_NAME $NAMESPACE)
  if [[ $exists != true ]]; then
    # If prod service does not exist start with blue environment
    echo $BLUE
    return
  fi

  yaml_path=$(fetch_service_yaml $PROD_SERVICE_NAME $NAMESPACE)

  env=$(get_annotation_value $yaml_path $ANNOTATION)
  if [[ $env == "null" ]]; then
    # If prod service does not have annotation start with blue environment
    echo $BLUE
    return
  fi

  if [[ $env == $BLUE ]]; then
    echo $GREEN
  else
    echo $BLUE
  fi;
}

main $@


