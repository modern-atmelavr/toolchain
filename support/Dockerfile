# Shorthands of all custom paths we are using
ARG CLI_DIR="/opt/ct/cli"
ARG PATCHES_DIR="/opt/ct/patches"
ARG DOWNLOADS_DIR="/opt/ct/downloads"
ARG BUILD_DIR="/opt/ct/build"
ARG TOOLCHAINS_DIR="/opt/ct/toolchains"
ARG TOOLCHAIN_ARCHIVES_DIR="/opt/ct/toolchain-archives"
ARG CT_REPO="https://github.com/crosstool-ng/crosstool-ng"
ARG CT_TAG="0145966e8e4f73843a72733e59263ce3f8c69f2e"



############################
FROM ubuntu:24.04 AS os-base

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NONINTERACTIVE_SEEN=true
RUN { echo 'tzdata tzdata/Areas select Etc'; \
      echo 'tzdata tzdata/Zones/Etc select UTC'; } | debconf-set-selections
RUN rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update \
 && apt full-upgrade -y \
 && apt install -y \
        autoconf \
        automake \
        bison \
        bzip2 \
        cmake \
        flex \
        g++ \
        gawk \
        gcc \
        git \
        gperf \
        help2man \
        jq \
        libncurses5-dev \
        libstdc++6 \
        libtool \
        libtool-bin \
        make \
        meson \
        mingw-w64 \
        ninja-build \
        patch \
        python3-dev \
        rsync \
        texinfo \
        unzip \
        wget \
        xz-utils \
    ;

FROM os-base AS base

# crosstool-ng doesn't like being run as root, so we hijack an existing "ubuntu" user. We only change its UID and GID
# to known values so that we know them - because docker cannot use usernames in `COPY --chown`, and there's no way
# to easily set ARG from the shell command (or no way at all?)
ARG BUILDER_UID=1000
ARG BUILDER_GID=1000
RUN groupmod ubuntu --gid "${BUILDER_GID}" \
 && usermod ubuntu --uid "${BUILDER_UID}"
USER ${BUILDER_UID}:${BUILDER_GID}

# WORKDIR creates the dir and its parents, and sets proper ownership for the hierarchy in one go. So we create
# the directories we would be using (ct-ng won't create them)
ARG CLI_DIR
ARG PATCHES_DIR
ARG DOWNLOADS_DIR
ARG BUILD_DIR
ARG TOOLCHAINS_DIR
ARG TOOLCHAIN_ARCHIVES_DIR
WORKDIR "${CLI_DIR}"
WORKDIR "${PATCHES_DIR}"
WORKDIR "${DOWNLOADS_DIR}"
WORKDIR "${BUILD_DIR}"
WORKDIR "${TOOLCHAINS_DIR}"
WORKDIR "${TOOLCHAIN_ARCHIVES_DIR}"

# Install crosstool-ng
WORKDIR "${CLI_DIR}"
ARG CT_REPO
ARG CT_TAG
RUN git clone "${CT_REPO}" "${CLI_DIR}" \
 && git checkout "${CT_TAG}"

COPY patches/packages "${CLI_DIR}/packages"

RUN ./bootstrap \
 && ./configure --enable-local \
 && make -j$(nproc)

ARG CONFIG="${CLI_DIR}/.config"
ARG CONFIG_IN="${CONFIG}.in"
COPY --chown=${BUILDER_UID}:${BUILDER_GID} config.in "${CONFIG_IN}"



######################
FROM base AS menuconfig

# Don't render any templates, so we won't need to reverse them back after menuconfig
RUN cp "${CONFIG_IN}" "${CONFIG}"

WORKDIR "${CLI_DIR}"

COPY scripts/run-menuconfig.sh .

CMD [ "./run-menuconfig.sh" ]

######################
FROM base AS config

COPY scripts/patch-config.py .
COPY --chown=${BUILDER_UID}:${BUILDER_GID} patches/config "${PATCHES_DIR}"

# Debug mode is required to make crosstool-ng save checkpoints for intermediate steps. We split the build process
# into steps instead of just going for `./ct-ng build`, because it takes really, really long for the job to finish,
# and just in case there is a build error in some late steps, you cannot even inspect what's wrong, because Docker
# will simply delete an incomplete image. With step checkpoints we can at least resume right before the problematic
# instruction and manually figure out what's wrong without having to wait for the full rebuild.
RUN ./patch-config.py "${CONFIG_IN}" "${PATCHES_DIR}/debug.patch" "${CONFIG_IN}"

# Depending on requested platform, patch the config file to make a toolchain with proper host type.
ARG PLATFORM
RUN case "${PLATFORM}" in \
      linux_x86_64) ;; \
      windows_amd64) ./patch-config.py "${CONFIG_IN}" "${PATCHES_DIR}/windows_amd64.patch" "${CONFIG_IN}"; \
                     ;; \
      *) echo "Unknown platform: \"${PLATFORM}\""; \
         exit 1; \
         ;; \
    esac



#######################
FROM config AS build

# Replace @@variables@@ in config with actual paths
RUN sed -e "s#@@DOWNLOADS_DIR@@#${DOWNLOADS_DIR}#g" \
        -e "s#@@BUILD_DIR@@#${BUILD_DIR}#g" \
        -e "s#@@TOOLCHAINS_DIR@@#${TOOLCHAINS_DIR}#g" \
        -e "s#@@TOOLCHAIN_ARCHIVES_DIR@@#${TOOLCHAIN_ARCHIVES_DIR}#g" \
        "${CONFIG_IN}" > "${CONFIG}"

WORKDIR "${CLI_DIR}"
COPY scripts/run-step.sh .

ARG resume_source
RUN ./run-step.sh source

# Steps obtained with `./ct-ng list-steps`:
#  - companion_tools_for_build
#  - companion_libs_for_build
#  - binutils_for_build
#  - companion_tools_for_host
#  - companion_libs_for_host
#  - binutils_for_host
#  - linker
#  - libc_headers
#  - kernel_headers
#  - cc_core
#  - libc_main
#  - cc_for_build
#  - cc_for_host
#  - libc_post_cc
#  - companion_libs_for_target
#  - binutils_for_target
#  - debug
#  - test_suite
#  - finish

# Every resume_* ARG allows to selectively invalidate cache after unsuccessful build. Since technically build completes
# (but taints all next layers with .fail), we need a way to make Docker reconsider some line as changed. Having an ARG
# changed to any value not used before (such as current timestamp) will make Docker rebuild starting from this
# particular ARG, which is what we need.

ARG resume_companion_tools_for_build
RUN ./run-step.sh +companion_tools_for_build

ARG resume_companion_libs_for_build
RUN ./run-step.sh companion_libs_for_build

ARG resume_binutils_for_build
RUN ./run-step.sh binutils_for_build

ARG resume_companion_tools_for_host
RUN ./run-step.sh companion_tools_for_host

ARG resume_companion_libs_for_host
RUN ./run-step.sh companion_libs_for_host

ARG resume_binutils_for_host
RUN ./run-step.sh binutils_for_host

ARG resume_linker
RUN ./run-step.sh linker

ARG resume_libc_headers
RUN ./run-step.sh libc_headers

ARG resume_kernel_headers
RUN ./run-step.sh kernel_headers

ARG resume_cc_core
RUN ./run-step.sh cc_core

ARG resume_libc_main
RUN ./run-step.sh libc_main

ARG resume_cc_for_build
RUN ./run-step.sh cc_for_build

ARG resume_cc_for_host
RUN ./run-step.sh cc_for_host

ARG resume_libc_post_cc
RUN ./run-step.sh libc_post_cc

ARG resume_companion_libs_for_target
RUN ./run-step.sh companion_libs_for_target

ARG resume_binutils_for_target
RUN ./run-step.sh binutils_for_target

ARG resume_debug
RUN ./run-step.sh debug

ARG resume_test_suite
RUN ./run-step.sh test_suite

ARG resume_finish
RUN ./run-step.sh finish



###############################
FROM os-base AS package

ARG TOOLCHAIN_ARCHIVES_DIR
ARG BUILD_DIR
ARG CLI_DIR
ARG PLATFORM
ENV PLATFORM="${PLATFORM}"

# glob has * in the name to account for possibly missing file - in this case it won't match anything. If we were just
# wrote `"${BUILD_DIR}"/.fail`, then COPY would've aborted the build if no .fail file could be found.
COPY --from=build "${BUILD_DIR}"/.fail* /

WORKDIR /opt/package
COPY --from=build "${TOOLCHAIN_ARCHIVES_DIR}" ./toolchains
COPY --from=build "${CLI_DIR}"/build.log /

COPY scripts/package.sh .
COPY config.in .
COPY manifests ./manifests

RUN ./package.sh

ENV PACKAGE_UID=1000
ENV PACKAGE_GID=1000
COPY scripts/export-package.sh .
CMD [ "./export-package.sh" ]
