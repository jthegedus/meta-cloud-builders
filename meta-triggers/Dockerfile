# hadolint ignore=DL3007
FROM gcr.io/cloud-builders/gcloud:latest

RUN apt-get -qq -y update \
	&& apt-get -qq -y --no-install-recommends install jq=1.6 \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

COPY yq /usr/bin
RUN chmod +x /usr/bin/yq

COPY run.sh /usr/bin
RUN chmod +x /usr/bin/run.sh

ENTRYPOINT [ "/usr/bin/run.sh" ]
