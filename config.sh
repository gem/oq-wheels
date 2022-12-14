#k Custom utilities for Fiona wheels.
#
# Test for OSX with [ -n "$IS_OSX" ].

function fetch_unpack {
    # Fetch input archive name from input URL
    # Parameters
    #    url - URL from which to fetch archive
    #    archive_fname (optional) archive name
    #
    # Echos unpacked directory and file names.
    #
    # If `archive_fname` not specified then use basename from `url`
    # If `archive_fname` already present at download location, use that instead.
    local url=$1
    if [ -z "$url" ];then echo "url not defined"; exit 1; fi
    local archive_fname=${2:-$(basename $url)}
    local arch_sdir="${ARCHIVE_SDIR:-archives}"
    # Make the archive directory in case it doesn't exist
    mkdir -p $arch_sdir
    local out_archive="${arch_sdir}/${archive_fname}"
    # If the archive is not already in the archives directory, get it.
    if [ ! -f "$out_archive" ]; then
        # Source it from multibuild archives if available.
        local our_archive="${MULTIBUILD_DIR}/archives/${archive_fname}"
        if [ -f "$our_archive" ]; then
            ln -s $our_archive $out_archive
        else
            # Otherwise download it.
            curl --insecure -L $url > $out_archive
        fi
    fi
    # Unpack archive, refreshing contents, echoing dir and file
    # names.
    rm_mkdir arch_tmp
    install_rsync
    (cd arch_tmp && \
        untar ../$out_archive && \
        ls -1d * &&
        rsync --delete -ah * ..)
}


function build_geos {
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    build_simple geos $GEOS_VERSION https://download.osgeo.org/geos tar.bz2
}


function build_jsonc {
    if [ -e jsonc-stamp ]; then return; fi
    fetch_unpack https://s3.amazonaws.com/json-c_releases/releases/json-c-${JSONC_VERSION}.tar.gz
    (cd json-c-${JSONC_VERSION} \
        && cmake -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX . \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    if [ -n "$IS_OSX" ]; then
        for lib in $(ls ${BUILD_PREFIX}/lib/libjson-c.5*.dylib); do
            sudo install_name_tool -id $lib $lib
        done
        for lib in $(ls ${BUILD_PREFIX}/lib/libjson-c.dylib); do
            sudo install_name_tool -id $lib $lib
        done
    fi
    touch jsonc-stamp
}


function build_tiff {
    if [ -e tiff-stamp ]; then return; fi
    build_zlib
    build_jpeg
    # Error: Failed to download resource "libzip"
    # Download failed:
    # Homebrew-installed `curl` is not installed for: https://libzip.org/download/libzip-1.9.2.tar.xz
    if [ -n "$IS_OSX" ]; then brew install curl; else echo "compilation on ML" ; fi
    ensure_xz
    fetch_unpack https://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz
    (cd tiff-${TIFF_VERSION} \
        && mv VERSION VERSION.txt \
        && (patch -u --force < ../patches/libtiff-rename-VERSION.patch || true) \
        && ./configure \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch tiff-stamp
}


function build_proj {
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    if [ -e proj-stamp ]; then return; fi
    build_sqlite
    fetch_unpack http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
	(cd proj-${PROJ_VERSION}
    mkdir build
    cd build
    cmake .. \
    -DCMAKE_INSTALL_PREFIX=$PROJ_DIR \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_IPO=ON \
    -DBUILD_CCT:BOOL=OFF \
    -DBUILD_CS2CS:BOOL=OFF \
    -DBUILD_GEOD:BOOL=OFF \
    -DBUILD_GIE:BOOL=OFF \
    -DBUILD_GMOCK:BOOL=OFF \
    -DBUILD_PROJINFO:BOOL=OFF \
    -DCMAKE_PREFIX_PATH=$BUILD_PREFIX \
    -DBUILD_TESTING:BOOL=OFF
    cmake --build . -j4
    (if [ -n "$IS_OSX" ]; then sudo cmake --install . ; else cmake --install .; fi))
    touch proj-stamp
}


function build_sqlite {
    if [ -e sqlite-stamp ]; then return; fi
    fetch_unpack https://www.sqlite.org/2020/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
    (cd sqlite-autoconf-${SQLITE_VERSION} \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch sqlite-stamp
}


function build_expat {
    if [ -e expat-stamp ]; then return; fi
    #if [ -n "$IS_OSX" ]; then
    #    :
    #else
    #    fetch_unpack https://github.com/libexpat/libexpat/releases/download/R_2_2_6/expat-${EXPAT_VERSION}.tar.bz2
    #    (cd expat-${EXPAT_VERSION} \
    #        && ./configure --prefix=$BUILD_PREFIX \
    #        && make -j4 \
    #        && sudo make install)
    #fi
    fetch_unpack https://github.com/libexpat/libexpat/releases/download/R_2_4_9/expat-${EXPAT_VERSION}.tar.bz2
    (cd expat-${EXPAT_VERSION} \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch expat-stamp
}


function build_nghttp2 {
    if [ -e nghttp2-stamp ]; then return; fi
    fetch_unpack https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz
    (cd nghttp2-${NGHTTP2_VERSION}  \
        && ./configure --enable-lib-only --prefix=$BUILD_PREFIX \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch nghttp2-stamp
}


function build_openssl {
    if [ -e openssl-stamp ]; then return; fi
    fetch_unpack ${OPENSSL_DOWNLOAD_URL}/${OPENSSL_ROOT}.tar.gz
    check_sha256sum $ARCHIVE_SDIR/${OPENSSL_ROOT}.tar.gz ${OPENSSL_HASH}
    (cd ${OPENSSL_ROOT} \
        && ./config no-ssl2 no-shared -fPIC --prefix=$BUILD_PREFIX \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch openssl-stamp
}


function build_curl {
    if [ -e curl-stamp ]; then return; fi
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    build_nghttp2
    build_openssl
    #local flags="--prefix=$BUILD_PREFIX --with-nghttp2=$BUILD_PREFIX --with-libz --with-ssl"
    local flags="--prefix=$BUILD_PREFIX --with-libz --with-ssl"
    #fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    (cd curl-${CURL_VERSION} \
        && LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BUILD_PREFIX/lib:$BUILD_PREFIX/lib64 ./configure $flags \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch curl-stamp
}


function build_gdal {
    if [ -e gdal-stamp ]; then return; fi

    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"

    EXPAT_PREFIX=$BUILD_PREFIX
    GEOS_CONFIG="--with-geos=${BUILD_PREFIX}/bin/geos-config"

    fetch_unpack http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
    (cd gdal-${GDAL_VERSION} \
        && ./configure \
	        --with-crypto=yes \
	        --with-hide-internal-symbols \
            --disable-debug \
            --disable-static \
	        --disable-driver-elastic \
            --prefix=$BUILD_PREFIX \
            --with-curl=curl-config \
            --with-expat=${EXPAT_PREFIX} \
            ${GEOS_CONFIG} \
            --with-geotiff=internal \
            --with-gif \
            --with-jpeg \
            --with-libiconv-prefix=/usr \
            --with-libjson-c=${BUILD_PREFIX} \
            --with-libtiff=${BUILD_PREFIX} \
            --with-libz=/usr \
            --with-pam \
            --with-png \
            --with-proj=${PROJ_DIR} \
            --with-sqlite3=${BUILD_PREFIX} \
            --with-threads \
            --without-cfitsio \
            --without-ecw \
            --without-fme \
            --without-freexl \
            --without-gnm \
            --without-grass \
            --without-ingres \
            --without-jasper \
            --without-jp2mrsid \
            --without-jpeg12 \
            --without-kakadu \
            --without-libgrass \
            --without-libkml \
            --without-mrsid \
            --without-mysql \
            --without-odbc \
            --without-ogdi \
            --without-pcidsk \
            --without-pcraster \
            --without-perl \
            --without-pg \
            --without-python \
            --without-qhull \
            --without-xerces \
            --without-xml2 \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    if [ -n "$IS_OSX" ]; then
        :
    else
        strip -v --strip-unneeded ${BUILD_PREFIX}/lib/libgdal.so.*
    fi
    touch gdal-stamp
}


function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    #if [ -n "$IS_OSX" ]; then
    #    # Update to latest zlib for OSX build
    #    build_new_zlib
    #fi
    if [ -z "$IS_OSX" ]; then 
    	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
    	export LD_RUN_PATH=$LD_RUN_PATH:/usr/local/lib
    fi
    suppress build_nghttp2
    suppress build_openssl
    # Remove previously installed curl.
    #sudo rm -rf /usr/local/lib/libcurl*
    if [ -n "$IS_OSX" ]; then sudo rm -rf /usr/local/lib/libcurl* ; else rm -rf /usr/local/lib/libcurl* ; fi
    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    suppress build_zlib
    suppress build_curl
    suppress build_sqlite
    suppress build_tiff
    suppress build_proj
    if [[ "$REPO_DIR" != "pyproj" ]]; then
      suppress build_jpeg
      suppress build_libpng
      suppress build_jsonc
      suppress build_expat
      suppress build_geos
      suppress build_gdal
    fi
    if [ -n "$IS_OSX" ]; then
       export LDFLAGS="${LDFLAGS} -Wl,-rpath,${BUILD_PREFIX}/lib"
       if [[ "$REPO_DIR" == "pyproj" ]]; then
         export LDFLAGS="${LDFLAGS} -Wl,-rpath,${PROJ_DIR}/lib"
       fi
    fi
}


function run_tests {
    unset GDAL_DATA
    unset PROJ_LIB
    unset PROJ_DATA
    if [ -n "$IS_OSX" ]; then
        export PATH=$PATH:${BUILD_PREFIX}/bin
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
    else
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
        export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
        sudo apt-get update
        sudo apt-get install -y ca-certificates
    fi
    cp -R ../Fiona/tests ./tests
    GDAL_ENABLE_DEPRECATED_DRIVER_GTM=YES python -m pytest -vv tests -k "not test_collection_zip_http and not test_mask_polygon_triangle and not test_show_versions and not test_append_or_driver_error and not [PCIDSK] and not cannot_append[FlatGeobuf]"
    fio --version
    fio env --formats
    if [[ $MB_PYTHON_VERSION != "3.10" ]]; then
        pip install shapely && python ../test_fiona_issue383.py
    fi
}


function build_wheel_cmd {
    local cmd=${1:-pip_wheel_cmd}
    local repo_dir=${2:-$REPO_DIR}
    [ -z "$repo_dir" ] && echo "repo_dir not defined" && exit 1
    local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
    start_spinner
    if [ -n "$(is_function "pre_build")" ]; then pre_build; fi
    stop_spinner
    if [ -n "$BUILD_DEPENDS" ]; then
        pip3 install $(pip_opts) $BUILD_DEPENDS
    fi
    # for pyproj (cd $repo_dir && PIP_NO_BUILD_ISOLATION=0 PIP_USE_PEP517=0 $cmd $wheelhouse)
    (cd $repo_dir && PIP_NO_BUILD_ISOLATION=0 $cmd $wheelhouse)
    repair_wheelhouse $wheelhouse
}
