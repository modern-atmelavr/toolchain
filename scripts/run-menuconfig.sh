#!/bin/bash

set -oxue pipefail

./ct-ng menuconfig
cp .config /output/config.in
