FROM alpine:latest

RUN apk update && apk upgrade && \
  apk add --update --no-cache \
  bash \
  wget \
  python \
  py-pip

RUN pip install --upgrade awscli && apk -v --purge del py-pip

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
