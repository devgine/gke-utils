#!/bin/sh

set -e

echo "Container's IP address: $(awk 'END{print $1}' /etc/hosts)"

# check if the session is active
RESULT=$(gcloud config get-value account)
if [ -z "$RESULT" ]; then

  # Check if service account json file exists
  export CONFIG_FILE=/var/gcloud/config.json
  if [ ! -f "$CONFIG_FILE" ];then
    echo "Config file does not exists."
    exec "$@"
  fi

  # Retrieve configuration
  PROJECT_ID=$(jq -r ".project_id" < $CONFIG_FILE)
  echo "The project_id is: $PROJECT_ID"

  CLUSTER_NAME=$(jq -r ".gke.cluster_name" < $CONFIG_FILE)
  echo "The cluster_name is: $CLUSTER_NAME"

  CLUSTER_REGION=$(jq -r ".gke.cluster_region" < $CONFIG_FILE)
  echo "The cluster_region is: $CLUSTER_REGION"

  ARTIFACT_REGION=$(jq -r ".acr.region" < $CONFIG_FILE)
  echo "The artifact_region is: $ARTIFACT_REGION"

  # todo: use GOOGLE_APPLICATION_CREDENTIALS instead of CREDENTIALS_FILE
  # Check if service account json file exists
  export CREDENTIALS_FILE=/var/gcloud/credentials.json
  if [ ! -f "$CREDENTIALS_FILE" ];then
    echo "Credentials file does not exists."
    exec "$@"
  fi

  # Login to google console platform
  gcloud auth login -q --cred-file=$CREDENTIALS_FILE > /dev/null

  # Set project
  gcloud config set project "$PROJECT_ID"

  # Connection to kubernetes cluster
  gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$CLUSTER_REGION"

  if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    # todo: make optional connection to registry
    # Login helm to google artifact
    gcloud auth application-default print-access-token | \
      helm registry login -u oauth2accesstoken --password-stdin "https://${ARTIFACT_REGION}-docker.pkg.dev"
  fi
fi

exec "$@"
