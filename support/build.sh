#!/bin/bash

set -oxue pipefail

# If the build fails, we'd like to know why. To know why, we need build logs. But build logs are the part of container
# that will get discarded after build step fails. And `RUN --mount` won't help either - bind mounts are read-only, and
# cache mounts are cumbersome, not guaranteed, and are not accessible after build. Bummer.
#
# So I have designed the Dockerfile to not fail after build step fails. Instead, a fail flag file /.fail will be
# created in the container's root fs, and and subsequent build steps will be skipped - since they will check if there's
# a /.fail file.
#
# Then we can take a built container, check if it has /.fail flag in it, and if it does, then we can copy out build
# logs out of it and identify the issue.
#
# However, if Docker will think that steps have completed without errors, Docker will cache them. Which means, how can
# we resume building from the step when it failed without invalidating the whole cache? That's why I am using "cache
# buster ARG" trick - before every step I have defined an ARG name like `resume_${step_name}`. So when we need to resume
# build from particular step, we can set the ARG preceding the step to retry to some unique value (e.g. current UNIX
# time), and Docker will then invalidate the cache just for that layer and those depending on it.
#
# To make resuming build more convenient, we store the name of failed step into /.fail and read it from there, but it
# can be overridden by running make with RESUME=${step_name} argument

WIP_IMAGE="${IMAGE_NAME}:${PLATFORM}-wip"
RELEASE_IMAGE="${IMAGE_NAME}:${PLATFORM}"
FAIL_FLAG='/.fail'
BUILD_LOG='/build.log'

wip_run() {
  if ! docker inspect "${WIP_IMAGE}" >/dev/null 2>&1; then {
    exit 1
  }; fi

  docker run --rm "${WIP_IMAGE}" "$@"
}

get_resume_step() {
  wip_run cat "${FAIL_FLAG}" 2>/dev/null || :
}

get_resume_arg() {
  local resume
  resume="${RESUME:-$(get_resume_step)}"

  if [ -n "${resume}" ]; then {
    echo -ne "--build-arg resume_${resume}=$(date +%s).${RANDOM}"
  }; fi
}

build() {
  # shellcheck disable=SC2046 # (get_resume_arg is unquoted on purpose)
  docker build \
    --file support/Dockerfile \
    --build-arg PLATFORM="${PLATFORM}" \
    $(get_resume_arg) \
    -t "${WIP_IMAGE}" \
    --progress plain \
    --target package \
    .

  if wip_run [ -e "${FAIL_FLAG}" ]; then {
    return 1
  }; fi

  docker image tag "${WIP_IMAGE}" "${RELEASE_IMAGE}"
  docker image rm "${WIP_IMAGE}"
	docker buildx prune -f
}

extract_toolchain() {
  mkdir -p "${TOOLCHAINS_DIR}"

  docker run --rm \
    -e PACKAGE_UID="$(id -u)" \
    -e PACKAGE_GID="$(id -g)" \
    -v "${TOOLCHAINS_DIR}":/output \
    "${RELEASE_IMAGE}"
}

extract_build_log() {
  wip_run cat "${BUILD_LOG}" >"${ROOT_DIR}/build.log"
}

if build; then {
  extract_toolchain
}; else {
  extract_build_log
  exit 1
}; fi
