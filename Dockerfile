ARG NODE_VERSION=12
ARG JAVA_VERSION=14
ARG SONAR_SCANNER_VERSION=4.2.0.1873

FROM openjdk:${JAVA_VERSION}-alpine AS java
FROM node:${NODE_VERSION}-alpine    AS node

ARG JAVA_VERSION
ARG SONAR_SCANNER_VERSION

# OpenJDK
COPY --from=java /opt/openjdk-${JAVA_VERSION} /opt/openjdk-${JAVA_VERSION}
ENV JAVA_HOME /opt/openjdk-${JAVA_VERSION}
ENV PATH $JAVA_HOME/bin:$PATH

ADD https://bintray.com/sonarsource/SonarQube/download_file?file_path=org%2Fsonarsource%2Fscanner%2Fcli%2Fsonar-scanner-cli%2F${SONAR_SCANNER_VERSION}%2Fsonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip /tmp/sonar-scanner.zip

# GitLab Sonar Scanner
COPY sonar-scanner-run.sh /usr/bin
WORKDIR /tmp
RUN \
    unzip /tmp/sonar-scanner.zip && \
    mv -fv /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin && \
    mv -fv /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}/lib/* /usr/lib && \
    ls -lha /usr/bin/sonar* && \
    ln -s /usr/bin/sonar-scanner-run.sh /usr/bin/gitlab-sonar-scanner

# Other Tools
RUN apk --no-cache --update add \
	curl \
	g++ \
	git \
	jq \
	make \
	python3

ENTRYPOINT "/bin/sh"
