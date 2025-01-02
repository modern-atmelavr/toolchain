#!/bin/bash

set -oxue pipefail

if [ -e /.fail ]; then {
  echo "[ SKIP ] Packaging skipped due to fail flag"
  exit;
}; fi

chown -R "${PACKAGE_UID}":"${PACKAGE_GID}" output
cp -a output/*.tar.gz /output/
