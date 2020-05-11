FROM alpine:3.11

RUN apk update && apk upgrade && \
  apk add --update --no-cache \
  bash \
  git \
  jq \
  python \
  py-pip

RUN pip install --upgrade awscli && apk -v --purge del py-pip

COPY functions.sh /functions.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
