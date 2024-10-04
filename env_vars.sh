LIBPNG_VERSION=1.6.35
ZLIB_VERSION=1.2.11
JPEG_VERSION=9c
GEOS_VERSION=3.11.2
JSONC_VERSION=0.15
SQLITE_VERSION=3440000
PROJ_VERSION=9.1.0
PROJ_DATA_VER=1.15.0
GDAL_VERSION=3.7.3
CURL_VERSION=8.4.0
NGHTTP2_VERSION=1.46.0
EXPAT_VERSION=2.4.9
TIFF_VERSION=4.3.0
OPENSSL_DOWNLOAD_URL=https://www.openssl.org/source/
OPENSSL_ROOT=openssl-1.1.1w
OPENSSL_HASH=cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8
export MACOSX_DEPLOYMENT_TARGET=10.15
export GDAL_CONFIG=/usr/local/bin/gdal-config
export PACKAGE_DATA=1
#from PROJ 9.x
export PROJ_DIR=/usr/local/
export PROJ_DATA=${PROJ_DIR}share/proj
export PROJ_WHEEL=true
export PROJ_NETWORK=ON
export SETUPTOOLS_USE_DISTUTILS=local
if [[ "$REPO_DIR" == "pyproj" ]]; then
 export PROJ_DIR=${GITHUB_WORKSPACE}/pyproj/pyproj/proj_dir
 export PROJ_DATA=${PROJ_DIR}/share/proj
 if [ -z "$IS_OSX" ]; then
	 echo "PROJ_DIR on ManyLinux  "
     export PROJ_DIR=/io/pyproj/pyproj/proj_dir
     export PROJ_DATA=${PROJ_DIR}/share/proj
 fi
fi
