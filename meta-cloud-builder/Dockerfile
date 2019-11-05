FROM gcr.io/cloud-builders/git

RUN apt-get -qq -y update \
    && apt-get -qq -y install jq

ADD yq /usr/bin
RUN chmod +x /usr/bin/yq

ADD run.sh /usr/bin
RUN chmod +x /usr/bin/run.sh

ENTRYPOINT [ "/usr/bin/run.sh" ]
