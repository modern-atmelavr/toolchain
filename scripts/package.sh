#!/bin/bash

set -oxue pipefail

if [ -e /.fail ]; then {
  echo "[ SKIP ] Packaging skipped due to fail flag"
  exit;
}; fi

echo "Unpacking toolchain..."
mkdir -p prep
tar xf toolchains/*.tar.xz --strip-components=1 -C prep

echo "Adding manifest..."
version="$(sed -En '/CT_GCC_VERSION=/s/CT_GCC_VERSION="([^"]+)"/\1/p' config.in)"
jq --arg version "${version}" -s '.[0] * .[1] | .version = $version' \
  "manifests/package.json" \
  "manifests/system.${PLATFORM}.json" \
  > "prep/package.json"

echo "Adding build log"
gzip -c -9 /build.log >prep/build.log.gz

echo "Packing toolchain..."
mkdir -p output
tar -czf "output/toolchain-atmelavr-libstdcxx.${PLATFORM}.tar.gz" -C prep .

echo "Cleaning up..."
rm -rf prep
