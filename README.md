# image-mirror

Container image mirror for the Eclipse Che ecosystem. Mirrors upstream images from rate-limited registries (DockerHub, GHCR) to `quay.io/che-incubator/image-mirror`.

## Two-lane model

Images under `quay.io/che-incubator/image-mirror/` come from two lanes:

| Lane | Source | How |
|------|--------|-----|
| **Mirror** | This repo | `skopeo copy` from upstream, no modifications |
| **Build** | Separate `*-image` repos | Custom Dockerfiles, multi-arch builds |

Currently:

| Image | Lane | Source repo |
|-------|------|-------------|
| `hermes-agent` | Mirror | this repo |
| `picoclaw` | Mirror | this repo |
| `zeroclaw` | Mirror | this repo |
| `zeroclaw-che` | Build | [che-incubator/zeroclaw-image](https://github.com/che-incubator/zeroclaw-image) |

## Adding a mirrored image

Edit `images.yaml` and add an entry:

```yaml
  - name: my-image
    source: docker.io/upstream/my-image
    destination: quay.io/che-incubator/image-mirror/my-image
    tags:
      - v1.0.0
      - latest
```

## How it works

- `mirror.sh` reads `images.yaml` and runs `skopeo copy --all` for each image:tag pair
- Multi-arch manifests are preserved automatically
- One failed image does not abort the rest

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Mirror Images** | push to main, daily schedule, manual | Mirror all or a specific image to quay.io |
| **Validate Images** | pull request | Check that all source images exist |
| **Check New Tags** | weekly (Monday), manual | Discover new upstream tags and open a PR |

## Manual trigger

- **Mirror**: Actions > Mirror Images > Run workflow. Enter an image name or leave empty for all.
- **Check tags**: Actions > Check New Tags > Run workflow.

## Running locally

```bash
# requires skopeo and yq
skopeo login quay.io
bash mirror.sh           # mirror all
bash mirror.sh picoclaw  # mirror one image
```

## Secrets

| Secret | Purpose |
|--------|---------|
| `QUAY_USERNAME` | Quay.io robot account username |
| `QUAY_PASSWORD` | Quay.io robot account token |
