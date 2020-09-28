FROM alpine:3.11

RUN apk update && apk upgrade && \
  apk add --update --no-cache \
  bash \
  curl \
  python \
  py-pip

RUN pip install --upgrade awscli && apk -v --purge del py-pip

RUN curl -o /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux/amd64-latest && \
  chmod +x /usr/local/bin/ecs-cli

COPY functions.sh /functions.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
