# See https://wiki.ubuntu.com/Releases
ARG UBUNTU_VERSION=focal

FROM ubuntu:${UBUNTU_VERSION} AS ubuntu

LABEL maintainer="Lorenz Leutgeb <lorenz.leutgeb@sclable.com>"

# See https://github.com/opencontainers/image-spec/blob/775207bd45b6cb8153ce218cc59351799217451f/annotations.md
LABEL org.opencontainers.image.title="Build Bundle"
LABEL org.opencontainers.image.url="https://git.sclable.com/sclable-platform/devops/kubernetes-cluster.git"
LABEL org.opencontainers.image.vendor="Sclable Business Solutions GmbH"
LABEL org.opencontainers.image.version="0.0.3"

# See https://jdk.java.net/
ARG JAVA_VERSION=11

# See https://nodejs.org/en/about/releases/
ARG NODE_VERSION=14

# See https://bintray.com/sonarsource/SonarQube/org.sonarsource.scanner.cli
ARG SONAR_SCANNER_VERSION=4.3.0.2102

# See https://www.php.net/releases/index.php
ARG PHP_VERSION=7.4

ARG UBUNTU_VERSION

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
	autoconf \
	build-essential \
	ca-certificates \
	curl \
	gettext \
	git \
	gnupg \
	jq \
	make \
    maven \
	nodejs \
	openjdk-${JAVA_VERSION}-jre-headless \
	python3 \
	python3-pip \
	unzip \
&& rm -rf /var/lib/apt/lists/*

# PHP
RUN echo "\
deb http://ppa.launchpad.net/ondrej/php/ubuntu ${UBUNTU_VERSION} main\n\
deb-src http://ppa.launchpad.net/ondrej/php/ubuntu ${UBUNTU_VERSION} main\n\
" > /etc/apt/sources.list.d/ppa-ondrej-php.list
RUN curl -L "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c" \
| apt-key add - \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y -q php${PHP_VERSION} \
&& rm -rf /var/lib/apt/lists/*

# NodeJS
RUN echo "\
deb https://deb.nodesource.com/node_${NODE_VERSION}.x ${UBUNTU_VERSION} main\n\
deb-src https://deb.nodesource.com/node_${NODE_VERSION}.x ${UBUNTU_VERSION} main\n\
" > /etc/apt/sources.list.d/nodesource.list
RUN curl -L https://deb.nodesource.com/gpgkey/nodesource.gpg.key nodesource.gpg.key \
| apt-key add - \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y -q nodejs \
&& rm -rf /var/lib/apt/lists/*

# GitLab Sonar Scanner
COPY sonar-scanner-run.sh /usr/bin
ADD https://dl.bintray.com/sonarsource/SonarQube/org/sonarsource/scanner/cli/sonar-scanner-cli/${SONAR_SCANNER_VERSION}/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip /tmp/sonar-scanner.zip
RUN \
    unzip /tmp/sonar-scanner.zip -d /tmp && \
    mv -fv /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin && \
    mv -fv /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}/lib/* /usr/lib && \
    ls -lha /usr/bin/sonar* && \
    ln -s /usr/bin/sonar-scanner-run.sh /usr/bin/gitlab-sonar-scanner

RUN pip3 install --no-cache-dir yq
