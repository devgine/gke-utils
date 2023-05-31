ARG K8S_VERSION=1.26.3
ARG CLOUD_SDK_VERSION=432.0.0

FROM alpine/k8s:${K8S_VERSION} as k8s
FROM google/cloud-sdk:${CLOUD_SDK_VERSION}-alpine

ARG CLOUD_SDK_VERSION
ARG K8S_VERSION

# Needed to use new GKE auth mechanism for kubeconfig
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True
# Useful for gcloud auth application-default command
ENV GOOGLE_APPLICATION_CREDENTIALS=/var/gcloud/credentials/credentials.json

## oniguruma: Useful for GoTemplate (jq)
RUN apk add -u --no-cache \
    oniguruma \
    && gcloud components install gke-gcloud-auth-plugin

COPY --from=k8s /usr/bin/kubectl /k8s/kubectl
COPY --from=k8s /usr/bin/helm /k8s/helm
COPY --from=k8s /usr/bin/kustomize /k8s/kustomize
COPY --from=k8s /usr/bin/kubeseal /k8s/kubeseal
COPY --from=k8s /usr/bin/yq /k8s/yq
COPY --from=k8s /usr/bin/jq /k8s/jq
COPY --from=k8s /usr/bin/jp.py /k8s/jp.py

ENV PATH $PATH:/k8s

WORKDIR /var/gke-utils

VOLUME /root/.kube
VOLUME /root/.docker
VOLUME /root/.config
VOLUME /root/.cache

HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD gcloud version || exit 1

# @see https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
COPY .docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["tail", "-f", "/dev/null"]

ARG BUILD_DATE
ARG VCS_REF
ARG BUILD_VERSION
ARG IMAGE_TAG=ghcr.io/devgine/gke-utils:latest

## LABELS
LABEL maintainer="Yosri BAHRI <yosribahri@gmail.com>"
LABEL org.opencontainers.image.title="GKE $CLOUD_SDK_VERSION and K8S $K8S_VERSION"
LABEL org.opencontainers.image.description="This is a docker image based on official alpine image and google cloud sdk \
v$CLOUD_SDK_VERSION and necessary tools to manage a kubernetes cluster hosted in GKE (google kubernetes engine). \
This image contains kubectl, helm, kustomize and kubeseal binaries."
LABEL org.opencontainers.image.source="https://github.com/devgine/gke-utils"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.url="https://github.com/devgine/gke-utils"
LABEL org.opencontainers.image.version=$BUILD_VERSION
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.vendor="devgine"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="devgine/gke-utils"
LABEL org.label-schema.description="This is a docker image based on official alpine image and google cloud sdk \
v$CLOUD_SDK_VERSION and necessary tools to manage a kubernetes cluster hosted in GKE (google kubernetes engine). \
This image contains kubectl, helm, kustomize and kubeseal binaries."
LABEL org.label-schema.url="https://github.com/devgine/gke-utils"
LABEL org.label-schema.vcs-url="https://github.com/devgine/gke-utils"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vendor="devgine"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run --rm -ti -v PATH/config.json:/var/gcloud/config.json \
-v PATH/credentials.json:/var/gcloud/credentials.json -v MANIFEST_DIRECTORY:/var/gke-utils $IMAGE_TAG sh"
