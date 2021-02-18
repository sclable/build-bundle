# See https://wiki.ubuntu.com/Releases
ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION} AS ubuntu

ARG UBUNTU_VERSION
ARG DOCKLE_VERSION
ARG HADOLINT_VERSION
ARG JAVA_VERSION
ARG NODE_VERSION

ARG SONAR_SCANNER_VERSION=4.6.0.2311
ARG PHP_VERSION=7.4

LABEL maintainer="Lorenz Leutgeb <lorenz.leutgeb@sclable.com>"

# See https://github.com/opencontainers/image-spec/blob/775207bd45b6cb8153ce218cc59351799217451f/annotations.md
LABEL org.opencontainers.image.title="Build Bundle"
LABEL org.opencontainers.image.url="https://git.sclable.com/sclable-platform/devops/build-bundle.git"
LABEL org.opencontainers.image.vendor="Sclable Business Solutions GmbH"
LABEL org.opencontainers.image.version="0.0.4"

# Copy arguments to labels, so that we can externally check which
# versions this image contains.
LABEL com.sclable.dependency.dockle=$DOCKLE_VERSION
LABEL com.sclable.dependency.java=$JAVA_VERSION
LABEL com.sclable.dependency.hadolint=$HADOLINT_VERSION
LABEL com.sclable.dependency.node=$NODE_VERSION
LABEL com.sclable.dependency.ubuntu=$UBUNTU_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
	autoconf \
	build-essential \
	ca-certificates \
	curl \
	gettext \
	git \
	gnupg \
	jq \
	libtool \
	make \
	maven \
	openjdk-${JAVA_VERSION}-jre-headless \
	python3 \
	python3-pip \
	unzip \
&& rm -rf /var/lib/apt/lists/*

# PHP
RUN . /etc/lsb-release && echo "\
deb http://ppa.launchpad.net/ondrej/php/ubuntu ${DISTRIB_CODENAME} main\n\
deb-src http://ppa.launchpad.net/ondrej/php/ubuntu ${DISTRIB_CODENAME} main\n\
" > /etc/apt/sources.list.d/ppa-ondrej-php.list
RUN curl -L "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c" \
| apt-key add - \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends php${PHP_VERSION} \
&& rm -rf /var/lib/apt/lists/*

# NodeJS
RUN . /etc/lsb-release && echo "\
deb https://deb.nodesource.com/node_${NODE_VERSION}.x ${DISTRIB_CODENAME} main\n\
deb-src https://deb.nodesource.com/node_${NODE_VERSION}.x ${DISTRIB_CODENAME} main\n\
" > /etc/apt/sources.list.d/nodesource.list
RUN curl -L https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
| apt-key add - \
&& apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs \
&& rm -rf /var/lib/apt/lists/*

# GitLab Sonar Scanner
COPY sonar-scanner-run.sh /usr/bin
RUN curl -L -o sonar-scanner.zip https://dl.bintray.com/sonarsource/SonarQube/org/sonarsource/scanner/cli/sonar-scanner-cli/${SONAR_SCANNER_VERSION}/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip \
&& unzip sonar-scanner.zip \
&& mv -fv sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin \
&& mv -fv sonar-scanner-${SONAR_SCANNER_VERSION}/lib/* /usr/lib \
&& ls -lha /usr/bin/sonar* \
&& ln -s /usr/bin/sonar-scanner-run.sh /usr/bin/gitlab-sonar-scanner \
&& rm sonar-scanner.zip

RUN pip3 install --no-cache-dir yq

# Install Dockle
RUN curl -L -o dockle.deb https://github.com/goodwithtech/dockle/releases/download/v${DOCKLE_VERSION}/dockle_${DOCKLE_VERSION}_Linux-64bit.deb \
&& dpkg -i dockle.deb \
&& rm dockle.deb

# Install Haskell Dockerfile Linter
RUN curl -L -o /usr/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64 \
&& chmod a+x /usr/bin/hadolint

USER 1000
