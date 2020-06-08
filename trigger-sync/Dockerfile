# hadolint ignore=DL3007
FROM gcr.io/cloud-builders/gcloud:latest
LABEL MAINTAINER="https://github.com/jthegedus"

ENV YQ_VERSION="3.3.0"
ENV WGET_VERSION="1.17.1-1ubuntu1.5"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# setup deps
RUN apt-get -qq -y update \
  && apt-cache showpkg moreutils \
  && apt-get -qq -y --no-install-recommends install \
  "wget=${WGET_VERSION}" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# setup yq
RUN wget -qO- "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" > /usr/bin/yq
RUN chmod +x /usr/bin/yq

# setup entrypoint script
COPY run.bash /usr/bin
RUN chmod +x /usr/bin/run.bash

ENTRYPOINT [ "/usr/bin/run.bash" ]
