FROM alpine:3.13

RUN apk add --update --upgrade --no-cache bash

RUN apk update \
    && apk upgrade \
    && apk add --update bash curl unzip jq

ADD resource/ /opt/resource/
RUN chmod +x /opt/resource/*

WORKDIR /
ENTRYPOINT ["/bin/bash"]