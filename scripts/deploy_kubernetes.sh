#!/bin/bash

set -euo pipefail

create_kubeconfig(){
  echo "Creating kubeconfig file"
  outputs=$(terraform output -json)
  
  assume_role=$(echo $outputs | jq '.assume_role.value' | sed 's/"//g')
  TEMP_ROLE=`aws sts assume-role --role-arn $assume_role --role-session-name ci-authenticate-kubernetes-782`

  access_key=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.AccessKeyId')
  secret_access_key=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SecretAccessKey')
  session_token=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SessionToken')
  cluster_name=$(echo $outputs | jq  '.eks_cluster_id.value' | sed 's/"//g')

  AWS_ACCESS_KEY_ID=$access_key AWS_SECRET_ACCESS_KEY=$secret_access_key AWS_SESSION_TOKEN=$session_token aws eks\
    --region eu-west-2 update-kubeconfig --name $cluster_name --role-arn $assume_role
}

upgrade_auth_configmap(){
  outputs=$(terraform output -json)
  env=$(echo $outputs | jq '.env.value' | sed 's/"//g')
  cluster_role_arn=$(echo $outputs | jq '.eks_cluster_worker_iam_role_arn.value' | sed 's/"//g')
  echo "Deploying auth configmap"
  helm upgrade --install --atomic mojo-$env-ima-configmap ./kubernetes/auth-configmap --set rolearn=$cluster_role_arn
}

get_role_arn_for_account(){
  outputs=$(terraform output -json)
  env=$(echo $outputs | jq '.env.value' | sed 's/"//g')
  [[ $env == "production" ]] \
    && role_arn=`aws ssm get-parameter --name /terraform_staff_infrastructure_monitoring/$1/outputs | jq -r .Parameter.Value | jq .cloudwatch_exporter_assume_role_arn | sed 's/"//g'`\
    || role_arn=""
  echo $role_arn
}

upgrade_ima_chart(){
  outputs=$(terraform output -json)
  env=$(echo $outputs | jq '.env.value' | sed 's/"//g')
  cluster_role_arn=$(echo $outputs | jq '.eks_cluster_worker_iam_role_arn.value' | sed 's/"//g')
  prometheus_image_repo=$(echo $outputs | jq '.prometheus_repository_v2.value.repository_url' | sed 's/"//g')
  prometheus_thanos_storage_bucket_name=$(echo $outputs | jq '.prometheus_thanos_storage_bucket_name.value' | sed 's/"//g')
  prometheus_thanos_storage_kms_key_id=$(echo $outputs | jq '.prometheus_thanos_storage_kms_key_id.value' | sed 's/"//g')
  ecr_url="${SHARED_SERVICES_ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com"
  cloudwatch_exporter_image="${ecr_url}/cloudwatch-exporter"
  
  production_role_arn=$(get_role_arn_for_account "production")
  pre_production_role_arn=$(get_role_arn_for_account "pre-production")
  development_role_arn=$(get_role_arn_for_account "development")

  echo "Deploying IMA Helm chart"
  helm upgrade --install mojo-$env-ima ./kubernetes/prometheus-thanos --set \
environment=$env,\
prometheus.image=$prometheus_image_repo,\
alertmanager.image=prom/alertmanager,\
prometheusThanosStorageBucket.bucketName=$prometheus_thanos_storage_bucket_name,\
prometheusThanosStorageBucket.kmsKeyId=$prometheus_thanos_storage_kms_key_id,\
thanos.image=$TF_VAR_thanos_image_repository_url,\
cloudwatchExporter.assumeDevelopmentRoleArn=$development_role_arn,\
cloudwatchExporter.assumePreProductionRoleArn=$pre_production_role_arn,\
cloudwatchExporter.assumeProductionRoleArn=$production_role_arn,\
cloudwatchExporter.image=$cloudwatch_exporter_image
}

main(){
  export KUBECONFIG="./kubernetes/kubeconfig"

  create_kubeconfig
  upgrade_auth_configmap
  upgrade_ima_chart

  # Display all Pods
  echo "List of Pods:"
  kubectl get pods
}

main
