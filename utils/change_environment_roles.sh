#!/bin/bash

# Constants
BLUE="blue"
GREEN="green"

SCRIPT_DIR=$(dirname $0)
source $SCRIPT_DIR/util.sh

main() {

  # Parameters
  blue_TARGET_SERVICE=$1
  green_TARGET_SERVICE=$2
  STAGE_SERVICE_NAME="$3"
  PROD_SERVICE_NAME="$4"
  NAMESPACE="$5"

  current_stage_environment=$($SCRIPT_DIR/get_current_stage_environment.sh $PROD_SERVICE_NAME $NAMESPACE)
  echo "Current stage environment: $current_stage_environment"
  if [[ $current_stage_environment == $BLUE ]]; then
    current_prod_environment=$GREEN
  else
    current_prod_environment=$BLUE
  fi

  echo "Current prod environment: $current_prod_environment"
  current_stage_service_config=${current_stage_environment}_TARGET_SERVICE
  current_stage_service=${!current_stage_service_config}
  echo "Current stage service: $current_stage_service"
  current_prod_service_config=${current_prod_environment}_TARGET_SERVICE
  current_prod_service=${!current_prod_service_config}
  echo "Current prod service: $current_prod_service"

  echo "Updating prod service"
  exists=$(check_service_exists $current_stage_service $NAMESPACE)
  if [[ $exists == true ]]; then
    $SCRIPT_DIR/update_environment_service.sh $current_stage_service $PROD_SERVICE_NAME $current_stage_environment $NAMESPACE
    if [[ $? != 0 ]]; then
      exit $?
    fi
  else
    echo "Target service does not exist: $current_stage_service."
    exit 1
  fi

  echo "Updating stage service"
  exists=$(check_service_exists $current_prod_service $NAMESPACE)
  if [[ $exists == true ]]; then
    $SCRIPT_DIR/update_environment_service.sh $current_prod_service $STAGE_SERVICE_NAME $current_prod_environment $NAMESPACE
    if [[ $? != 0 ]]; then
      exit $?
    fi
  else
    echo "Target service does not exist: $current_prod_service. Skipping."
  fi
}

main $@