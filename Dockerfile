ARG NODE_VERSION=12
ARG JAVA_VERSION=14

FROM openjdk:${JAVA_VERSION}-alpine AS java
FROM ciricihq/gitlab-sonar-scanner  AS gitlab-sonar-scanner
FROM node:${NODE_VERSION}-alpine    AS node

ARG JAVA_VERSION

# OpenJDK
COPY --from=java /opt/openjdk-${JAVA_VERSION} /opt/openjdk-${JAVA_VERSION}
ENV JAVA_HOME /opt/openjdk-${JAVA_VERSION}
ENV PATH $JAVA_HOME/bin:$PATH

# GitLab Sonar Scanner
COPY --from=gitlab-sonar-scanner /usr/lib/sonar-scanner* /usr/lib
COPY --from=gitlab-sonar-scanner /usr/bin/sonar-scanner-run.sh /usr/bin/gitlab-sonar-scanner
COPY --from=gitlab-sonar-scanner /usr/bin/sonar-scanner /usr/bin/gitlab-sonar-scanner

# Other Tools
RUN apk --no-cache --update add \
	curl \
	g++ \
	git \
	jq \
	make \
	python3

ENTRYPOINT "/bin/sh"
