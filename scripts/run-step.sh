#!/bin/bash

set -oue pipefail

failflag="${BUILD_DIR}/.fail"

# If previous stages have failed, then exit early without doing anything
if [[ -e "${failflag}" ]]; then {
  echo "[ SKIP ] Some previous step has failed"
  exit
}; fi

# If the step has failed, then keep things as they are, indicate failure to the next steps and try to wrap up quickly
if ! ./ct-ng "$@"; then {
  # remove + sign from the step
  echo "$@" | tr -d '+' > "${failflag}";
}; fi
