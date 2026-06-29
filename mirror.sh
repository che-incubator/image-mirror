#!/bin/bash
#
# Mirror container images from images.yaml.
# Usage: ./mirror.sh [image-name]
#   No args: mirror all images
#   With arg: mirror only the named image
#
set -uo pipefail

IMAGES_FILE="${IMAGES_FILE:-images.yaml}"
FILTER="${1:-}"
FAILED=0
MIRRORED=0

image_count=$(yq '.images | length' "$IMAGES_FILE")
for i in $(seq 0 $((image_count - 1))); do
  name=$(yq ".images[$i].name" "$IMAGES_FILE")

  if [ -n "$FILTER" ] && [ "$FILTER" != "$name" ]; then
    continue
  fi

  src=$(yq ".images[$i].source" "$IMAGES_FILE")
  dst=$(yq ".images[$i].destination" "$IMAGES_FILE")
  tag_count=$(yq ".images[$i].tags | length" "$IMAGES_FILE")

  for j in $(seq 0 $((tag_count - 1))); do
    tag=$(yq ".images[$i].tags[$j]" "$IMAGES_FILE")
    echo "::group::Mirror: $src:$tag -> $dst:$tag"
    if skopeo copy --all "docker://$src:$tag" "docker://$dst:$tag"; then
      echo "OK"
      MIRRORED=$((MIRRORED + 1))
    else
      echo "::error::Failed: $src:$tag -> $dst:$tag"
      FAILED=$((FAILED + 1))
    fi
    echo "::endgroup::"
  done
done

echo "Mirrored: $MIRRORED, Failed: $FAILED"
if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
