FROM gcr.io/cloud-builders/git

RUN add-apt-repository ppa:rmescandon/yq \
    && apt-get -qq -y update \
    && apt-get -qq -y install yq jq

ADD run.sh /usr/bin
RUN chmod +x /usr/bin/run.sh

ENTRYPOINT [ "/usr/bin/run.sh" ]
