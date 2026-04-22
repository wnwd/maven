ARG JAVA_VERSION=21
FROM debian:bookworm-slim

ARG JAVA_VERSION=21
ARG MAVEN_VERSION=3.9.9
ARG MAVEN_MAJOR=3

LABEL org.opencontainers.image.title="java-maven" \
      org.opencontainers.image.description="Java ${JAVA_VERSION} + Apache Maven ${MAVEN_VERSION} on Debian Bookworm Slim"

ENV JAVA_HOME=/opt/java
ENV MAVEN_HOME=/opt/maven
ENV PATH="${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${PATH}"
ENV JAVA_VERSION=${JAVA_VERSION}
ENV MAVEN_VERSION=${MAVEN_VERSION}

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    rm -rf /var/lib/apt/lists/*; \
    # 根据 CPU 架构映射 Adoptium 的参数名
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
      amd64)   JDK_ARCH="x64"     ;; \
      arm64)   JDK_ARCH="aarch64" ;; \
      armhf)   JDK_ARCH="arm"     ;; \
      ppc64el) JDK_ARCH="ppc64le" ;; \
      s390x)   JDK_ARCH="s390x"   ;; \
      *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac; \
    # 从 Adoptium API 下载对应版本的最新 GA JDK
    curl -fsSL \
      "https://api.adoptium.net/v3/binary/latest/${JAVA_VERSION}/ga/linux/${JDK_ARCH}/jdk/hotspot/normal/eclipse" \
      -o /tmp/jdk.tar.gz; \
    mkdir -p /opt/java; \
    tar -xzf /tmp/jdk.tar.gz -C /opt/java --strip-components=1; \
    rm /tmp/jdk.tar.gz; \
    java -version; \
    # 安装指定版本的 Maven
    curl -fsSL \
      "https://archive.apache.org/dist/maven/maven-${MAVEN_MAJOR}/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
      -o /tmp/maven.tar.gz; \
    tar -xzf /tmp/maven.tar.gz -C /opt/; \
    ln -s "/opt/apache-maven-${MAVEN_VERSION}" "${MAVEN_HOME}"; \
    rm /tmp/maven.tar.gz; \
    mvn --version

CMD ["mvn", "--version"]
