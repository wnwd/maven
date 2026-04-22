# Java-Maven Docker Images

Automated Docker images combining Java LTS versions and Apache Maven, built daily via GitHub Actions and published to both Docker Hub and GitHub Container Registry.

## Images

| Registry | Image |
|----------|-------|
| Docker Hub | `YOUR_DOCKERHUB_USERNAME/java-maven` |
| GHCR | `ghcr.io/YOUR_GITHUB_USERNAME/java-maven` |

## Tags

Tags follow the pattern `java{JAVA_VERSION}-maven{MAVEN_VERSION}`:

| Tag | Example |
|-----|---------|
| Exact version | `java21-maven3.9.9` |
| Minor alias (always latest patch) | `java21-maven3.9` |

### Java versions tracked (LTS only)

`8` · `11` · `17` · `21` · `25`

### Maven versions tracked

| Minor | Description |
|-------|-------------|
| `3.6` | Maven 3.6.x latest patch |
| `3.8` | Maven 3.8.x latest patch |
| `3.9` | Maven 3.9.x latest patch |
| `4.0` | Maven 4.0.x latest patch (when released) |

## Usage

```bash
# Java 21 + Maven 3.9 (latest patch)
docker pull YOUR_DOCKERHUB_USERNAME/java-maven:java21-maven3.9

# Java 17 + Maven 3.8 exact version
docker pull ghcr.io/YOUR_GITHUB_USERNAME/java-maven:java17-maven3.8.8

# Use in a Dockerfile
FROM YOUR_DOCKERHUB_USERNAME/java-maven:java21-maven3.9
COPY . /app
WORKDIR /app
RUN mvn package -DskipTests
```

## Base Image

`eclipse-temurin:{JAVA_VERSION}-jdk-bookworm` (Debian Bookworm Slim, provided by [Adoptium](https://adoptium.net/))

Architectures: `linux/amd64`, `linux/arm64`

## Automated Builds

- **Daily schedule**: runs at UTC 02:00, checks for new Maven patch releases
- **Smart skip**: only builds tag combinations absent from [`versions.env`](./versions.env)
- **Force rebuild**: trigger manually via `workflow_dispatch` to rebuild all combinations regardless of `versions.env`
- **On push**: rebuilds automatically when `Dockerfile` or the workflow file changes

## Setup

### 1. Configure GitHub repository variables and secrets

| Name | Type | Value |
|------|------|-------|
| `DOCKERHUB_USERNAME` | Variable | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Secret | Docker Hub access token ([create one here](https://hub.docker.com/settings/security)) |

Go to **Settings → Secrets and variables → Actions** to add them.  
`GITHUB_TOKEN` for GHCR is provided automatically by GitHub Actions.

### 2. Add Maven version tracking (optional)

To track a new Maven minor (e.g. `3.5`, `4.1`), add it to `tracked_minors` in the workflow:

```yaml
tracked_minors = ['3.6', '3.8', '3.9', '4.0', '4.1']
```

### 3. Add a Java version (optional)

Add to `java_versions` in the workflow:

```python
java_versions = ['8', '11', '17', '21', '25', '29']
```

## Build Locally

```bash
docker build \
  --build-arg JAVA_VERSION=21 \
  --build-arg MAVEN_VERSION=3.9.9 \
  --build-arg MAVEN_MAJOR=3 \
  -t java-maven:java21-maven3.9.9 .
```

## `versions.env`

[`versions.env`](./versions.env) tracks which tags have been successfully built and pushed. It is updated automatically by the `update-versions` job after every successful build run. Do not edit it manually unless you want to force a specific combination to be rebuilt (remove its line).
