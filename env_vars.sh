LIBPNG_VERSION=1.6.35
ZLIB_VERSION=1.2.11
JPEG_VERSION=9c
GEOS_VERSION=3.10.2
JSONC_VERSION=0.15
SQLITE_VERSION=3330000
PROJ_VERSION=9.1.0
GDAL_VERSION=3.4.3
CURL_VERSION=7.80.0
NGHTTP2_VERSION=1.46.0
EXPAT_VERSION=2.4.9
TIFF_VERSION=4.3.0
OPENSSL_DOWNLOAD_URL=https://www.openssl.org/source/
OPENSSL_ROOT=openssl-1.1.1l
OPENSSL_HASH=0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1
export MACOSX_DEPLOYMENT_TARGET=10.10
export GDAL_CONFIG=/usr/local/bin/gdal-config
export PACKAGE_DATA=1
#from PROJ 9.x
export PROJ_DIR=/usr/local/
export PROJ_DATA=${PROJ_DIR}share/proj
export PROJ_WHEEL=true
export PROJ_NETWORK=ON
export SETUPTOOLS_USE_DISTUTILS=stdlib
if [[ "$REPO_DIR" == "pyproj" ]]; then
 export PROJ_DIR=${GITHUB_WORKSPACE}/pyproj/pyproj/proj_dir
 export PROJ_DATA=${PROJ_DIR}/share/proj
 if [ -z "$IS_OSX" ]; then 
	 echo "PROJ_DIR on ML2014  "
     export PROJ_DIR=/io/pyproj/pyproj/proj_dir
     export PROJ_DATA=${PROJ_DIR}/share/proj
	 echo "print PROJ_DIR: ${PROJ_DIR}"
	 echo "print PROJ_DATA: ${PROJ_DATA}"
	 export $LD_LIBRARY_PATH
 fi
fi
