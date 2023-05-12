#!/bin/sh

set -e

echo "Container's IP address: `awk 'END{print $1}' /etc/hosts`"

if [ "$1" = 'gcloud-service-account-auth' ]; then
  # todo: check if active session
  # todo: check if service account json file exists
  # Login with the service account
  gcloud auth login --cred-file=/var/.gcloud/service-account/kubernetes-service.json
  export GOOGLE_APPLICATION_CREDENTIALS=/var/.gcloud/service-account/kubernetes-service.json

  # todo: get cloud region from env var
  # gcloud config set project PROJECT_ID
  gcloud config set project sonic-shuttle-381413

  # Connection to kubernetes cluster
  # todo: get CLUSTER_NAME and COMPUTE_REGION from env var
  # gcloud container clusters get-credentials CLUSTER_NAME --region=COMPUTE_REGION
  gcloud container clusters get-credentials stack-cluster --region=europe-central2-a

  # todo: make optional connection to registry
  # todo: get cloud region from env var
  # Login helm to google artifact
  gcloud auth application-default print-access-token | \
    helm registry login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev
fi

exec "$@"
