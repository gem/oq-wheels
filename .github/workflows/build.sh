#!/usr/bin/env bash
set -ex 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/geolibs.sh"
BUILD_PREFIX="${BUILD_PREFIX:-/opt/geostack}"
BUILD_DIR="${BUILD_DIR:-/tmp/geostack-build}"
mkdir -p "$BUILD_PREFIX" "$BUILD_DIR"
OS="$(uname -s)"

# =========================
# OS SETUP
# =========================

setup_linux() {
    export CFLAGS="-fPIC ${CFLAGS:-}"
    export CXXFLAGS="-fPIC ${CXXFLAGS:-}"
}
setup_macos() {
    export MACOSX_DEPLOYMENT_TARGET="11.0"
}
setup_windows() {
    export CMAKE_GENERATOR="Ninja"
}

case "$OS" in
    Linux) setup_linux ;;
    Darwin) setup_macos ;;
    MINGW*|MSYS*|CYGWIN*) setup_windows ;;
    *) echo "Unsupported OS: $OS"; exit 1 ;;
esac


TARGET="${BUILD_TARGET:-gdal}"
case "$TARGET" in
    gdal)
        build_gdal
        ;;
    proj)
        build_proj
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac
