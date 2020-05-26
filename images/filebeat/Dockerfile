ARG VERSION

FROM docker.elastic.co/beats/filebeat:${VERSION}

USER root
ADD config/filebeat.yml /usr/share/filebeat/filebeat.yml
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml
RUN chmod 0640 /usr/share/filebeat/filebeat.yml
