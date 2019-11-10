FROM gcr.io/cloud-builders/gcloud

ADD yq /usr/bin
RUN chmod +x /usr/bin/yq

ADD run.sh /usr/bin
RUN chmod +x /usr/bin/run.sh

ENTRYPOINT [ "/usr/bin/run.sh" ]
