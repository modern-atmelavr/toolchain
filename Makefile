ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

menuconfig_sh := $(ROOT_DIR)support/menuconfig.sh
build_sh := $(ROOT_DIR)support/build.sh
release_sh := $(ROOT_DIR)support/release.sh

TOOLCHAINS_DIR := $(ROOT_DIR)toolchains/
toolchain_prefix := $(TOOLCHAINS_DIR)toolchain-atmelavr-libstdcxx.
toolchain_suffix := .tar.gz

config_in := $(ROOT_DIR)config.in

VERSION = $(shell sed -En '/^CT_GCC_VERSION=/s/^CT_GCC_VERSION="([^"]+)"/\1/p' "$(config_in)")
IMAGE_NAME = avr-toolchain
RESUME =

PLATFORMS := linux_x86_64 windows_amd64

.EXPORT_ALL_VARIABLES:

.PHONY: menuconfig all clean distclean release $(PLATFORMS)

menuconfig:
	$(menuconfig_sh)

linux_x86_64: $(toolchain_prefix)linux_x86_64$(toolchain_suffix)

windows_amd64: $(toolchain_prefix)windows_amd64$(toolchain_suffix)

all: $(PLATFORMS)

clean:
	rm -rf "$(toolchain_prefix)"*"$(toolchain_suffix)"

distclean: clean
	docker image rm -f \
		$(foreach platform, $(PLATFORMS), \
			"$(IMAGE_NAME)":$(platform) "$(IMAGE_NAME)":$(platform)-wip \
		) \
		"$(IMAGE_NAME)":menuconfig
	docker buildx prune -f

release: $(PLATFORMS)
	$(release_sh) $(FORCE)

$(foreach platform, $(PLATFORMS), \
	$(toolchain_prefix)$(platform)$(toolchain_suffix): $(config_in) ; \
		PLATFORM=$(platform) $(build_sh))
