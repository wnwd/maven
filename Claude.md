# CLAUDE.md

## Project Overview

This repo automates building and publishing Docker images that bundle Java LTS + Apache Maven. It has no application code — the primary artifacts are:

- `Dockerfile` — parameterized build accepting `JAVA_VERSION`, `MAVEN_VERSION`, `MAVEN_MAJOR`
- `.github/workflows/build-and-push.yml` — 3-job pipeline (detect → build → update)
- `versions.env` — plain-text record of already-published tags (auto-maintained by CI)

## Workflow Logic

```
detect-versions
  ├─ Fetches Maven metadata XML from Maven Central
  ├─ Resolves latest patch for each tracked minor (3.6 / 3.8 / 3.9 / 4.0)
  ├─ Reads versions.env to find already-built tags
  └─ Outputs: matrix (new combos only), has_new flag, desired tag list

build-push  [matrix, skipped if has_new == false]
  ├─ Builds linux/amd64 + linux/arm64 via docker/build-push-action
  └─ Pushes exact-version tag + minor-alias tag to Docker Hub and GHCR

update-versions  [runs only if ALL build-push jobs succeed]
  └─ Overwrites versions.env with the full desired tag list and commits [skip ci]
```

`workflow_dispatch` sets `FORCE=true`, which skips the versions.env comparison and rebuilds everything.

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Single parameterized image; base is `eclipse-temurin:{JAVA_VERSION}-jdk-bookworm` |
| `.github/workflows/build-and-push.yml` | Full CI pipeline |
| `versions.env` | Tracks built tags; edit to force a rebuild of specific combinations |

## Tag Convention

- Exact: `java21-maven3.9.9`
- Minor alias (floating): `java21-maven3.9`

## Extending

- **New Maven minor**: add to `tracked_minors` list in the `detect-versions` Python script
- **New Java version**: add to `java_versions` list in the same script
- **New registry**: add a login step and extra tag lines in `build-push`

## Secrets / Variables Required

| Name | Where | Description |
|------|-------|-------------|
| `DOCKERHUB_USERNAME` | Repository Variable | Docker Hub username |
| `DOCKERHUB_TOKEN` | Repository Secret | Docker Hub access token |
| `GITHUB_TOKEN` | Auto-provided | Used for GHCR push |

## Local Build

```bash
docker build \
  --build-arg JAVA_VERSION=21 \
  --build-arg MAVEN_VERSION=3.9.9 \
  --build-arg MAVEN_MAJOR=3 \
  -t java-maven:local .
```
