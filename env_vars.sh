SQLITE_VERSION=3540100
CURL_VERSION=8.23.0
LIBPNG_VERSION=1.6.59
ZLIB_VERSION=1.4
JPEG_VERSION=10
GEOS_VERSION=3.15.0
JSONC_VERSION=0.18
PROJ_VERSION=9.9.0
PROJ_DATA_VER=1.24.0
HDF5_VERSION=1.14.6
GDAL_VERSION=3.13.3
NGHTTP2_VERSION=1.71.0
EXPAT_VERSION=2.10.0
OPENSSL_DOWNLOAD_URL=https://www.openssl.org/source/
OPENSSL_ROOT=openssl-3.5.0
OPENSSL_HASH=344d0a79f1a9b08029b0744e2cc401a43f9c90acd1044d09a530b4885a8e9fc0
TIFF_VERSION=4.7.2
PCRE_VERSION=10.49
PYOGRIO_VERSION=v0.13.0
export MACOSX_DEPLOYMENT_TARGET=14.0
if [ -z "$IS_OSX" ] || [ "$PLAT" == arm_64 ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
export GDAL_CONFIG=/usr/local/bin/gdal-config
export PACKAGE_DATA=1
#from PROJ 9.x
export PROJ_DIR=/usr/local/
export PROJ_DATA=${PROJ_DIR}share/proj
export PROJ_WHEEL=true
export PROJ_NETWORK=ON
#export SETUPTOOLS_USE_DISTUTILS=stdlib
if [[ "$REPO_DIR" == "pyproj" ]]; then
 export PROJ_DIR=${GITHUB_WORKSPACE}/pyproj/pyproj/proj_dir
 export PROJ_DATA=${PROJ_DIR}/share/proj
 if [ -z "$IS_OSX" ]; then
	 echo "PROJ_DIR on ManyLinux  "
     export PROJ_DIR=/io/pyproj/pyproj/proj_dir
     export PROJ_DATA=${PROJ_DIR}/share/proj
 fi
fi
