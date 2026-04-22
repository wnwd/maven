ARG JAVA_VERSION=21
FROM eclipse-temurin:${JAVA_VERSION}-jdk-bookworm

ARG MAVEN_VERSION=3.9.9
ARG MAVEN_MAJOR=3

LABEL org.opencontainers.image.title="java-maven" \
      org.opencontainers.image.description="Java ${JAVA_VERSION} + Apache Maven ${MAVEN_VERSION} on Debian Slim"

ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"
ENV JAVA_VERSION=${JAVA_VERSION}
ENV MAVEN_VERSION=${MAVEN_VERSION}

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    DOWNLOAD_URL="https://archive.apache.org/dist/maven/maven-${MAVEN_MAJOR}/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"; \
    curl -fsSL "${DOWNLOAD_URL}" -o /tmp/maven.tar.gz; \
    tar -xzf /tmp/maven.tar.gz -C /opt/; \
    ln -s "/opt/apache-maven-${MAVEN_VERSION}" "${MAVEN_HOME}"; \
    rm /tmp/maven.tar.gz; \
    mvn --version

CMD ["mvn", "--version"]
