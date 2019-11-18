ARG UBUNTU_VERSION=bionic

FROM ubuntu:${UBUNTU_VERSION} AS ubuntu

LABEL maintainer="Lorenz Leutgeb <lorenz.leutgeb@sclable.com>"

# See https://github.com/opencontainers/image-spec/blob/775207bd45b6cb8153ce218cc59351799217451f/annotations.md
LABEL org.opencontainers.image.title="Build Bundle"
LABEL org.opencontainers.image.url="https://git.sclable.com/sclable-platform/devops/kubernetes-cluster.git"
LABEL org.opencontainers.image.vendor="Sclable Business Solutions GmbH"
LABEL org.opencontainers.image.version="0.0.1"

ARG JAVA_VERSION=11
ARG NODE_VERSION=13
ARG SONAR_SCANNER_VERSION=4.2.0.1873
ARG UBUNTU_VERSION

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
	build-essential \
	ca-certificates \
	curl \
	gettext \
	git \
	gnupg \
	jq \
	make \
	nodejs \
	openjdk-${JAVA_VERSION}-jre-headless \
	python3 \
	unzip \
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
