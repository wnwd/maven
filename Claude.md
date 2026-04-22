# CLAUDE.md

## Project Overview

This repo automates building and publishing Docker images that bundle Java LTS + Apache Maven. It has no application code — the primary artifacts are:

- `Dockerfile` — parameterized build accepting `JAVA_VERSION`, `MAVEN_VERSION`, `MAVEN_MAJOR`
- `.github/workflows/build-and-push.yml` — 3-job pipeline (detect → build → update)
- `versions.env` — plain-text record of already-published tags (auto-maintained by CI)

## Base Image Design

Uses `debian:bookworm-slim` as the fixed base, with JDK fetched at build time from the **Adoptium API**:

```
https://api.adoptium.net/v3/binary/latest/{JAVA_VERSION}/ga/linux/{arch}/jdk/hotspot/normal/eclipse
```

This was chosen over `eclipse-temurin:{version}-jdk-bookworm` because eclipse-temurin's Debian bookworm tags are inconsistent across Java versions — some (e.g. Java 25) are only published as UBI variants, not Debian. Using the Adoptium API directly ensures every Java LTS version gets the same `debian:bookworm-slim` base.

## Workflow Logic

```
detect-versions
  ├─ Fetches Maven metadata XML from Maven Central
  ├─ Resolves latest patch for each tracked minor (3.6 / 3.8 / 3.9 / 4.0)
  ├─ Reads versions.env to find already-built tags
  └─ Outputs:
       matrix   — new combos only (for build-push job)
       has_new  — 'true'/'false' flag (gates build-push)
       desired  — full newline-separated list of all expected tags
                  (used by update-versions to overwrite versions.env)

build-push  [matrix, skipped if has_new == 'false']
  ├─ Builds linux/amd64 + linux/arm64 via docker/build-push-action
  └─ Pushes two tags per combo:
       exact:        java21-maven3.9.9
       minor alias:  java21-maven3.9   (floating, points to latest patch)

update-versions  [runs only if ALL build-push jobs succeed]
  └─ Overwrites versions.env with the `desired` output from detect-versions
     and commits with [skip ci] to avoid triggering another run
```

`workflow_dispatch` sets `FORCE=true` in the Python script, which skips the `versions.env` diff and adds all combos to the matrix regardless.

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Parameterized; base is `debian:bookworm-slim`, JDK from Adoptium API |
| `.github/workflows/build-and-push.yml` | Full CI pipeline |
| `versions.env` | Tracks built tags; delete a line to force that combo to rebuild |

## Tag Convention

- Exact: `java21-maven3.9.9`
- Minor alias (floating): `java21-maven3.9`

## Extending

- **New Maven minor**: add to `tracked_minors` in the `detect-versions` Python script
- **New Java LTS version**: add to `candidate_java_versions`; Adoptium availability is checked automatically
- **New registry**: add a login step and extra tag lines in `build-push`

## Secrets / Variables Required

| Name | Where | Description |
|------|-------|-------------|
| `DOCKERHUB_USERNAME` | Repository Variable | Docker Hub username |
| `DOCKERHUB_TOKEN` | Repository Secret | Docker Hub access token |
| `GITHUB_TOKEN` | Auto-provided | Used for GHCR push (`packages: write` permission set on job) |

## Local Build

```bash
docker build \
  --build-arg JAVA_VERSION=21 \
  --build-arg MAVEN_VERSION=3.9.9 \
  --build-arg MAVEN_MAJOR=3 \
  -t java-maven:local .
```
