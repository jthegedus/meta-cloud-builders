FROM gcr.io/cloud-builders/git

RUN add-apt-repository ppa:rmescandon/yq
RUN apt-get -qq -y update \
    && apt-get -qq -y install jq

# ADD yq_linux_amd64 /usr/bin
# RUN chmod +x /usr/bin/yq_linux_amd64

ADD run.sh /usr/bin
RUN chmod +x /usr/bin/run.sh

ENTRYPOINT [ "/usr/bin/run.sh" ]
