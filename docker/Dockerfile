FROM openjdk:8-jre-alpine

RUN apk update && apk upgrade && \
  apk add --update --no-cache \
  bash \
  curl \
  jq \
  git \
  openssh \
  python \
  py-pip

RUN pip install --upgrade awscli && apk -v --purge del py-pip

COPY . /flyway

WORKDIR /flyway

ENV FLYWAY_VERSION 6.4.0

RUN wget https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}.tar.gz \
  && tar -xzf flyway-commandline-${FLYWAY_VERSION}.tar.gz \
  && mv flyway-${FLYWAY_VERSION}/* . \
  && rm flyway-commandline-${FLYWAY_VERSION}.tar.gz

CMD ["/flyway/flyway". "-?"]
