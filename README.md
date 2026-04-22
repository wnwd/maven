# java-maven Docker Images

Automated Docker images combining Java LTS versions and Apache Maven, built daily via GitHub Actions and published to both Docker Hub and GitHub Container Registry.

## Images

| Registry | Image |
|----------|-------|
| Docker Hub | `YOUR_DOCKERHUB_USERNAME/java-maven` |
| GHCR | `ghcr.io/YOUR_GITHUB_USERNAME/java-maven` |

## Tags

Tags follow the pattern `java{JAVA_VERSION}-maven{MAVEN_VERSION}`:

| Tag | Description |
|-----|-------------|
| `java21-maven3.9.9` | 精确版本，构建时固定 |
| `java21-maven3.9` | minor 别名，始终指向 3.9.x 最新 patch |

### Java LTS 版本

`8` · `11` · `17` · `21` · `25`

> 每日由 [Adoptium API](https://api.adoptium.net) 自动检测 GA 可用性，尚未发布的版本自动跳过。

### Maven 版本

| Minor | 说明 |
|-------|------|
| `3.6` | 3.6.x 最新 patch |
| `3.8` | 3.8.x 最新 patch |
| `3.9` | 3.9.x 最新 patch |
| `4.0` | 4.0.x 最新 patch（发布后自动纳入）|

## Usage

```bash
# Java 21 + Maven 3.9（最新 patch）
docker pull YOUR_DOCKERHUB_USERNAME/java-maven:java21-maven3.9

# Java 17 + Maven 3.8 精确版本（来自 GHCR）
docker pull ghcr.io/YOUR_GITHUB_USERNAME/java-maven:java17-maven3.8.8

# 在 Dockerfile 中使用
FROM YOUR_DOCKERHUB_USERNAME/java-maven:java21-maven3.9
COPY . /app
WORKDIR /app
RUN mvn package -DskipTests
```

## Base Image

`debian:bookworm-slim`，JDK 通过 [Adoptium API](https://api.adoptium.net) 下载安装。

> **为什么不用 `eclipse-temurin:*-jdk-bookworm`？**  
> eclipse-temurin 的 bookworm tag 命名不统一，部分 Java 版本（如 25）仅发布了 UBI 变体，没有 Debian 变体。直接在 `debian:bookworm-slim` 上调用 Adoptium API 可以保证所有 LTS 版本使用相同的基础镜像，且能随时获取最新 GA JDK。

支持架构：`linux/amd64` · `linux/arm64` · `linux/ppc64le` · `linux/s390x`

## 自动构建逻辑

```
detect-versions
  ├─ 从 Maven Central 获取各 minor 最新 patch 版本
  ├─ 通过 Adoptium API 确认每个 Java 版本有 GA 发布
  ├─ 读取 versions.env，过滤已构建的 tag
  └─ 输出：待构建矩阵 / has_new 标志 / 本次期望的完整 tag 列表

build-push  [矩阵并行，has_new=false 时跳过]
  └─ 构建并推送 精确版本 tag + minor 别名 tag 到 Docker Hub 和 GHCR

update-versions  [全部 build-push 成功后执行]
  └─ 用本次期望的完整 tag 列表覆写 versions.env，commit [skip ci]
```

- **每日定时**：UTC 02:00 运行，有新版本才构建
- **智能跳过**：精确版本 tag 已记录在 `versions.env` 则跳过
- **强制重建**：通过 `workflow_dispatch` 手动触发，忽略 `versions.env` 重建全部组合
- **代码变更**：`Dockerfile` 或 workflow 文件有 push 时自动触发

## 配置

### 1. 配置仓库变量和 Secrets

进入 **Settings → Secrets and variables → Actions** 添加：

| 名称 | 类型 | 说明 |
|------|------|------|
| `DOCKERHUB_USERNAME` | Variable（变量）| Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | Secret（密钥）| Docker Hub Access Token（[在此创建](https://hub.docker.com/settings/security)）|

> `GITHUB_TOKEN` 由 GitHub Actions 自动提供，无需手动配置。

### 2. 追踪新的 Maven minor（可选）

在 workflow 的 `detect-versions` Python 脚本中添加：

```python
tracked_minors = ['3.6', '3.8', '3.9', '4.0', '4.1']
```

### 3. 追踪新的 Java LTS 版本（可选）

```python
candidate_java_versions = ['8', '11', '17', '21', '25', '29']
```

> 添加后，脚本会自动通过 Adoptium API 检查该版本是否有 GA 发布，未发布则跳过，无需其他改动。

## 本地构建

```bash
docker build \
  --build-arg JAVA_VERSION=21 \
  --build-arg MAVEN_VERSION=3.9.9 \
  --build-arg MAVEN_MAJOR=3 \
  -t java-maven:java21-maven3.9.9 .
```

## `versions.env`

[`versions.env`](./versions.env) 记录已成功构建并推送的镜像 tag，由 `update-versions` job 在每次全量成功后自动覆写。

**手动干预**：若需强制重新构建某个组合，从文件中删除对应行，然后触发 `workflow_dispatch` 即可。
