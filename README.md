# GKE Utilities

## About
This is a docker image based on official alpine image and google cloud sdk and necessary tools to manage a kubernetes cluster hosted in GKE (google kubernetes engine).<br />
Available tools in this image :
* gcloud
* gke-gcloud-auth-plugin
* kubectl
* helm
* kustomize
* kubeseal

## Content

Below is the list of tools with their preinstalled version.

| Image tag                                                   | Alpine | gcloud  | kubectl | helm | kustomize | kubeseal |
|-------------------------------------------------------------|--------|---------|---------|------|-----------|----------|
| `gke-utils:latest`<br/>`gke-utils:432.0.0-k8s1.27.1-alpine` | 3.17   | 432.0.0 | 1.27    | 3.11 | 5.0       | 0.20     |
| `gke-utils:432.0.0-k8s1.26.3-alpine`                        | 3.17   | 432.0.0 | 1.26    | 3.11 | 5.0       | 0.20     |
| `gke-utils:432.0.0-k8s1.25.9-alpine`                        | 3.17   | 432.0.0 | 1.25    | 3.11 | 5.0       | 0.20     |
| `gke-utils:432.0.0-k8s1.24.13-alpine`                       | 3.17   | 432.0.0 | 1.24    | 3.11 | 5.0       | 0.20     |


## Requirements
### Credentials
To connect to the cluster on GKE you must download the service account or the identity federation pool credentials.
The credentials file should be mounted to `/var/gcloud/credentials.json` in the container.<br>
> More information about creating service account credentials [here](https://support.google.com/a/answer/7378726?hl=en)

### Configuration
You need to do some configuration to connect to the correct cluster in GKE.<br>
The configuration file should be mounted to `/var/gcloud/config.json` in the container.

Bellow is the content of the configuration file :
```json
{
  "project_id": "project-id-1234",
  "gke": {
    "cluster_name": "cluster-name",
    "cluster_region": "europe-central2-a"
  },
  "acr": {
    "region": "us-central1"
  }
}
```

| Config key         | Required | Description                                          |
|--------------------|----------|------------------------------------------------------|
| project_id         | true     | The  GCP project id                                  |
| gke.cluster_name   | true     | The name of your cluster in GKE                      |
| gke.cluster_region | true     | The region of your cluster in GKE                    |
| acr.region         | false    | The region of your artifact or registry (ACR or GCR) |

> The `acr.region` is required only if you use helm to deploy into the cluster.

## Usage
### Use with docker
```shell
docker run --rm -ti \
  -v PATH/config.json:/var/gcloud/config.json \
  -v PATH/credentials.json:/var/gcloud/credentials.json \
  -v MANIFEST_DIRECTORY:/var/gke-utils \
  ghcr.io/devgine/gke-utils:latest sh
```
Connect to the container and check if connection to the cluster is done.
```shell
kubectl config get-contexts
```
### Use with docker-compose

```yaml
version: '3.8'

services:
  kubernetes:
    image: ghcr.io/devgine/gke-utils:latest
    container_name: kubernetes
    volumes:
      - './manifest/:/var/gke-utils'
      - './.gcloud/:/var/gcloud' # .gcloud/ dir contains config.json and credentials.json files
      - 'kube_data:/root/.kube'
      - 'docker_data:/root/.docker'
      - 'config_data:/root/.config'
      - 'cache_data:/root/.cache'

volumes:
  kube_data:
    driver: local
  docker_data:
    driver: local
  config_data:
    driver: local
  cache_data:
    driver: local
```

> `manifest` directory contains the kubernetes manifest<br>
> `.gcloud` directory contains config.json and credentials.json<br>

Connect to the container
```shell
docker-compose up -d && docker-compose exec kubernetes sh
```
Check if connection to the cluster is done.
```shell
kubectl config get-contexts
```

### Use in Dockerfile
```dockerfile
FROM ghcr.io/devgine/gke-utils:latest

# Add your specific instruction here (exp: install terraform)
RUN release=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
RUN wget https://releases.hashicorp.com/terraform/${release}/terraform_${release}_linux_amd64.zip
RUN unzip terraform_${release}_linux_amd64.zip
RUN mv terraform /usr/bin/terraform
```

## References

### GKE releases
https://cloud.google.com/kubernetes-engine/docs/release-notes

### Google cloud SDK
https://hub.docker.com/r/google/cloud-sdk/

### K8S
https://hub.docker.com/r/alpine/k8s
