#!/bin/bash

set -oue pipefail

version="$(sed -En '/CT_GCC_VERSION=/s/CT_GCC_VERSION="([^"]+)"/\1/p' config.in)"
tag_name="v${version}"

banner=""
git_opts=()
if [ "${FORCE:-0}" -ne 0 ]; then {
  banner=" (forced)"
  git_opts+=("-f")
}; fi

echo "Releasing ${version}...${banner}"

if [ "${FORCE:-0}" -ne 0 ]; then {
  echo "Deleting previous release..."
  gh release delete "${tag_name}" --cleanup-tag --yes || true
}; fi

echo "Creating tag..."
git tag -a "${tag_name}" -m "$(support/get-tag-message.py)" "${git_opts[@]}"

echo "Pushing tag to the remote..."
git push --tag "${git_opts[@]}"

echo "Creating release..."
gh release create \
  --notes-from-tag \
  --title "AVR-GCC ${version}" \
  --verify-tag \
  "${tag_name}" \
  toolchains/toolchain-atmelavr-libstdcxx.*.tar.gz
