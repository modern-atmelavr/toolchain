#!/bin/bash

set -oxue pipefail

docker build \
  --file support/Dockerfile \
  -t "${IMAGE_NAME}":menuconfig \
  --progress plain \
  --target menuconfig \
  .

docker run \
  --rm -it \
  -v "${ROOT_DIR}/config.in:/output/config.in" \
  "${IMAGE_NAME}":menuconfig
