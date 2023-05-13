ARG BUILD_DATE
ARG VCS_REF
ARG K8S_VERSION=1.26.3

FROM alpine/k8s:${K8S_VERSION}

LABEL maintainer="Yosri BAHRI <yosribahri@gmail.com>"
LABEL org.label-schema.build-date="$BUILD_DATE"
LABEL org.label-schema.description="Google kubernetes engine utilities (gcloud - kubectl - kubeseal - kustomize - helm)"
LABEL org.label-schema.vcs-ref="$VCS_REF"
LABEL org.label-schema.vcs-url="https://github.com/devgine/gke-utils"

# renovate: datasource=docker depName=gcr.io/google.com/cloudsdktool/google-cloud-cli
ARG CLOUD_SDK_VERSION=426.0.0

ENV PATH $PATH:/usr/local/google-cloud-sdk/bin

# Needed to use new GKE auth mechanism for kubeconfig
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True
# Useful for gcloud auth application-default command
ENV GOOGLE_APPLICATION_CREDENTIALS=/var/gcloud/credentials/credentials.json

RUN apk add --update --no-cache \
    bash \
    curl \
    docker \
    openrc \
    # google-cloud-sdk \
    && curl -sSL https://sdk.cloud.google.com | bash \
    && curl --silent --fail --show-error -L -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz -C /usr/local \
    && rm -f google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && gcloud config set core/disable_usage_reporting true \
    && gcloud config set component_manager/disable_update_check true \
    && gcloud components install gke-gcloud-auth-plugin

WORKDIR /var/gke-utils

## todo add volumes
VOLUME /root/.kube
VOLUME /root/.docker
VOLUME /root/.config
VOLUME /root/.cache

HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD gcloud version || exit 1

# @see https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["tail", "-f", "/dev/null"]
