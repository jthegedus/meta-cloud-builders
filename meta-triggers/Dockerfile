# hadolint ignore=DL3007
FROM gcr.io/cloud-builders/gcloud:latest

ENV JQ_VERION="1.5+dfsg-1ubuntu0.1"
ENV YQ_VERSION="3.3.0"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# setup jq
RUN apt-get -qq -y update \
	&& apt-cache showpkg wget \ 
	&& apt-get -qq -y --no-install-recommends install "jq=${JQ_VERION}" wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# setup yq
RUN wget -qO- "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" > /usr/bin/yq
RUN chmod +x /usr/bin/yq

# setup entrypoint script
COPY run.sh /usr/bin
RUN chmod +x /usr/bin/run.sh

ENTRYPOINT [ "/usr/bin/run.sh" ]
