#!/bin/bash

check_service_exists() {
  service_name=$1
  namespace=$2

  service=$(kubectl get service $service_name -n $namespace 2>&1)
  result=$?
  if [[ $result == 0 ]]; then
    echo true
  else
    echo false
  fi
}

fetch_service_json() {
  service_name=$1
  namespace=$2

  tmp_dir=$(mktemp -d -t pipelines-XXXXXXXXXX)
  kubectl get service $service_name -n $namespace -o json > $tmp_dir/service.json
  echo $tmp_dir/service.json
}

get_annotation_value() {
  file_path=$1
  annotation_path=.metadata.annotations.\"$2\"
  jq -r $annotation_path $file_path
}

create_temporary_service_json_copy() {
  file_path=$1
  tmp_dir=$(mktemp -d -t pipelines-XXXXXXXXXX)
  cp $file_path $tmp_dir/service.json
  echo $tmp_dir/service.json
}