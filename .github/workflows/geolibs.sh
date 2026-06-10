#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# import versions
source "${SCRIPT_DIR}/env_vars.sh"

MULTIBUILD_DIR=$(dirname "${BASH_SOURCE[0]}")
DOWNLOADS_SDIR=downloads

function start_spinner {
    if [ -n "$MB_SPINNER_PID" ]; then
        return
    fi

    >&2 echo "Building libraries..."
    # Start a process that runs as a keep-alive
    # to avoid travis quitting if there is no output
    (while true; do
        sleep 60
        >&2 echo "Still building..."
    done) &
    MB_SPINNER_PID=$!
    disown
}

function stop_spinner {
    if [ ! -n "$MB_SPINNER_PID" ]; then
        return
    fi

    kill $MB_SPINNER_PID
    unset MB_SPINNER_PID

    >&2 echo "Building libraries finished."
}

function any_python {
    for cmd in $PYTHON_EXE python3 python; do
        if [ -n "$(type -t $cmd)" ]; then
            echo $cmd
            return
        fi
    done
    echo "Could not find python or python3"
    exit 1
}

function abspath {
    # Can work with any Python; need not be our installed Python.
    $(any_python) -c "import os.path; print(os.path.abspath('$1'))"
}

function relpath {
    # Path of first input relative to second (or $PWD if not specified)
    # Can work with any Python; need not be our installed Python.
    $(any_python) -c "import os.path; print(os.path.relpath('$1','${2:-$PWD}'))"
}

function realpath {
    # Can work with any Python; need not be our installed Python.
    $(any_python) -c "import os; print(os.path.realpath('$1'))"
}

function lex_ver {
    # Echoes dot-separated version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}

function unlex_ver {
    # Reverses lex_ver to produce major.minor.micro
    # Thus:
    # 003002001 -> 3.2.1
    # 003000000 -> 3.0.0
    echo "$((10#${1:0:3}+0)).$((10#${1:3:3}+0)).$((10#${1:6:3}+0))"
}

function strip_ver_suffix {
    echo $(unlex_ver $(lex_ver $1))
}

function is_function {
    # Echo "true" if input argument string is a function
    # Allow errors during "set -e" blocks.
    (set +e; $(declare -Ff "$1" > /dev/null) && echo true)
}

function gh_clone {
    git clone https://github.com/$1
}

# gh-clone was renamed to gh_clone, so we have this alias for
# backwards compatibility.
alias gh-clone=gh_clone

function set_opts {
    # Set options from input options string (in $- format).
    local opts=$1
    local chars="exhmBH"
    for (( i=0; i<${#chars}; i++ )); do
        char=${chars:$i:1}
        [ -n "${opts//[^${char}]/}" ] && set -$char || set +$char
    done
}

function suppress {
    # Run a command, show output only if return code not 0.
    # Takes into account state of -e option.
    # Compare
    # https://unix.stackexchange.com/questions/256120/how-can-i-suppress-output-only-if-the-command-succeeds#256122
    # Set -e stuff agonized over in
    # https://unix.stackexchange.com/questions/296526/set-e-in-a-subshell
    local tmp=$(mktemp tmp.XXXXXXXXX) || return
    local errexit_set
    echo "Running $@"
    if [[ $- = *e* ]]; then errexit_set=true; fi
    set +e
    ( if [[ -n $errexit_set ]]; then set -e; fi; "$@"  > "$tmp" 2>&1 ) ; ret=$?
    [ "$ret" -eq 0 ] || cat "$tmp"
    rm -f "$tmp"
    if [[ -n $errexit_set ]]; then set -e; fi
    return "$ret"
}

function expect_return {
  # Run a command, succeeding (returning 0) only if the commend returns a specified code
  # Parameters
  #   retcode   expected return code (which may be zero)
  #   command   the command called
  #
  #   any further arguments are passed to the called command
  #
  # Returns 1 if called with less than 2 arguments
  (( $# < 2 )) && echo "Must have at least 2 arguments" && return 1
  local retcode=$1
  local retval
  ( "${@:2}" ) || retval=$?
  [[ $retcode == ${retval:-0} ]] && return 0
  return ${retval:-1}
}

function cmd_notexit {
    # wraps a command, capturing its return code and preventing it
    # from exiting the shell. Handles -e / +e modes.
    # Parameters
    #    cmd - command
    #    any further parameters are passed to the wrapped command
    # If called without an argument, it will exit the shell with an error
    local cmd=$1
    if [ -z "$cmd" ];then echo "no command"; exit 1; fi
    if [[ $- = *e* ]]; then errexit_set=true; fi
    set +e
    ("${@:1}") ; retval=$?
    [[ -n $errexit_set ]] && set -e
    return $retval
}

function rm_mkdir {
    # Remove directory if present, then make directory
    local path=$1
    if [ -z "$path" ]; then echo "Need not-empty path"; exit 1; fi
    if [ -d "$path" ]; then rm -rf $path; fi
    mkdir $path
}

function untar {
    local in_fname=$1
    if [ -z "$in_fname" ];then echo "in_fname not defined"; exit 1; fi
    local extension=${in_fname##*.}
    case $extension in
        tar) tar -xf $in_fname ;;
        gz|tgz) tar -zxf $in_fname ;;
        bz2) tar -jxf $in_fname ;;
        zip) unzip -qq $in_fname ;;
        xz) if [ -n "$IS_MACOS" ]; then
              tar -xf $in_fname
            else
              if [[ ! $(type -P "unxz") ]]; then
                echo xz must be installed to uncompress file; exit 1
              fi
              unxz -c $in_fname | tar -xf -
            fi ;;
        *) echo Did not recognize extension $extension; exit 1 ;;
    esac
}

function install_rsync {
    # install rsync via package manager
    if [ -n "$IS_MACOS" ]; then
        # macOS. The colon in the next line is the null command
        :
    elif [ -n "$IS_ALPINE" ]; then
        [[ $(type -P rsync) ]] || apk add rsync
    elif [[ $MB_ML_VER == "_2_24" ]]; then
        # debian:9 based distro
        [[ $(type -P rsync) ]] || apt-get install -y rsync
    else
        # centos based distro
        [[ $(type -P rsync) ]] || yum_install rsync
    fi
}

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
    if [ -e geos-stamp ]; then return; fi
    local cmake=cmake
    fetch_unpack http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2
    (cd geos-${GEOS_VERSION} \
        && mkdir build && cd build \
        && $cmake .. \
        -DCMAKE_INSTALL_PREFIX:PATH=$BUILD_PREFIX \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_IPO=ON \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        && $cmake --build . -j4 \
        && $cmake --install .)
    touch geos-stamp
}
function build_jsonc {
    if [ -e jsonc-stamp ]; then return; fi
    local cmake=cmake
    fetch_unpack https://s3.amazonaws.com/json-c_releases/releases/json-c-${JSONC_VERSION}.tar.gz
    (cd json-c-${JSONC_VERSION} \
        && $cmake -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET . \
        && make -j4 \
        && make install)
    if [ -n "$IS_OSX" ]; then
        for lib in $(ls ${BUILD_PREFIX}/lib/libjson-c.5*.dylib); do
            install_name_tool -id $lib $lib
        done
        for lib in $(ls ${BUILD_PREFIX}/lib/libjson-c.dylib); do
            install_name_tool -id $lib $lib
        done
    fi
    touch jsonc-stamp
}
function build_proj {
    CFLAGS="$CFLAGS -DPROJ_RENAME_SYMBOLS -g -O2"
    CXXFLAGS="$CXXFLAGS -DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -g -O2"
    if [ -e proj-stamp ]; then return; fi
    local cmake=cmake
    build_sqlite
    fetch_unpack http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
    (cd proj-${PROJ_VERSION} \
        && mkdir build && cd build \
        && $cmake .. \
        -DCMAKE_INSTALL_PREFIX:PATH=$BUILD_PREFIX \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_IPO=ON \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        && $cmake --build . -j4 \
        && $cmake --install .)
    touch proj-stamp
}
function build_tiff {
    if [ -e tiff-stamp ]; then return; fi
    build_zlib
    build_jpeg
    build_xz
    fetch_unpack https://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz
    (cd tiff-${TIFF_VERSION} \
        && mv VERSION VERSION.txt \
        && (patch -u --force < ../patches/libtiff-rename-VERSION.patch || true) \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    touch tiff-stamp
}
function build_sqlite {
    if [ -e sqlite-stamp ]; then return; fi
    fetch_unpack https://www.sqlite.org/2020/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
    (cd sqlite-autoconf-${SQLITE_VERSION} \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    touch sqlite-stamp
}
function build_expat {
    if [ -e expat-stamp ]; then return; fi
    if [ -n "$IS_OSX" ]; then
        :
    else
        fetch_unpack https://github.com/libexpat/libexpat/releases/download/R_2_2_6/expat-${EXPAT_VERSION}.tar.bz2
        (cd expat-${EXPAT_VERSION} \
            && ./configure --prefix=$BUILD_PREFIX \
            && make -j4 \
            && make install)
    fi
    touch expat-stamp
}
function build_nghttp2 {
    if [ -e nghttp2-stamp ]; then return; fi
    fetch_unpack https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz
    (cd nghttp2-${NGHTTP2_VERSION}  \
        && ./configure --enable-lib-only --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    touch nghttp2-stamp
}
function build_openssl {
    if [ -e openssl-stamp ]; then return; fi
    fetch_unpack ${OPENSSL_DOWNLOAD_URL}/${OPENSSL_ROOT}.tar.gz
    check_sha256sum $ARCHIVE_SDIR/${OPENSSL_ROOT}.tar.gz ${OPENSSL_HASH}
    (cd ${OPENSSL_ROOT} \
        && ./config no-ssl2 -fPIC --prefix=$BUILD_PREFIX \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch openssl-stamp
}
function build_curl {
    if [ -e curl-stamp ]; then return; fi
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    build_openssl
    build_nghttp2
    local flags="--prefix=$BUILD_PREFIX --with-nghttp2=$BUILD_PREFIX --with-libz --with-ssl  --without-libidn2"
    #    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    (cd curl-${CURL_VERSION} \
        && LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BUILD_PREFIX/lib:$BUILD_PREFIX/lib64 ./configure $flags \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch curl-stamp
}
function build_pcre2 {
    build_simple pcre2 $PCRE_VERSION https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE_VERSION}
}
function build_gdal {
    if [ -e gdal-stamp ]; then return; fi
    build_curl
    build_jpeg
    build_libpng
    build_jsonc
    build_tiff
    build_proj
    build_sqlite
    build_expat
    build_geos
    build_pcre2
    CFLAGS="$CFLAGS -DPROJ_RENAME_SYMBOLS -g -O2"
    CXXFLAGS="$CXXFLAGS -DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -g -O2"
    if [ -n "$IS_OSX" ]; then
        GEOS_CONFIG="-DGDAL_USE_GEOS=OFF"
        PCRE2_LIB="$BUILD_PREFIX/lib/libpcre2-8.dylib"
    else
        GEOS_CONFIG="-DGDAL_USE_GEOS=ON"
        PCRE2_LIB="$BUILD_PREFIX/lib/libpcre2-8.so"
    fi
    local cmake=cmake
    fetch_unpack http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
    (cd gdal-${GDAL_VERSION} \
        && mkdir build \
        && cd build \
        && $cmake .. \
        -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX \
        -DCMAKE_INCLUDE_PATH=$BUILD_PREFIX/include \
        -DCMAKE_LIBRARY_PATH=$BUILD_PREFIX/lib \
        -DCMAKE_PROGRAM_PATH=$BUILD_PREFIX/bin \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DGDAL_BUILD_OPTIONAL_DRIVERS=OFF \
        -DOGR_BUILD_OPTIONAL_DRIVERS=ON \
        ${GEOS_CONFIG} \
        -DGDAL_USE_TIFF=ON \
        -DGDAL_USE_TIFF_INTERNAL=OFF \
        -DGDAL_USE_GEOTIFF_INTERNAL=ON \
        -DGDAL_ENABLE_DRIVER_GIF=ON \
        -DGDAL_ENABLE_DRIVER_GRIB=ON \
        -DGDAL_ENABLE_DRIVER_JPEG=ON \
        -DGDAL_USE_ICONV=ON \
        -DGDAL_USE_JSONC=ON \
        -DGDAL_USE_JSONC_INTERNAL=OFF \
        -DGDAL_USE_ZLIB=ON \
        -DGDAL_USE_ZLIB_INTERNAL=OFF \
        -DGDAL_ENABLE_DRIVER_PNG=ON \
        -DGDAL_ENABLE_DRIVER_OGCAPI=OFF \
        -DOGR_ENABLE_DRIVER_GPKG=ON \
        -DBUILD_PYTHON_BINDINGS=OFF \
        -DBUILD_JAVA_BINDINGS=OFF \
        -DBUILD_CSHARP_BINDINGS=OFF \
        -DGDAL_USE_SFCGAL=OFF \
        -DGDAL_USE_XERCESC=OFF \
        -DGDAL_USE_LIBXML2=OFF \
        -DGDAL_USE_PCRE2=ON \
        -DPCRE2_INCLUDE_DIR=$BUILD_PREFIX/include \
        -DPCRE2-8_LIBRARY=$PCRE2_LIB \
        -DGDAL_USE_POSTGRESQL=OFF \
        -DGDAL_USE_ODBC=OFF \
        && $cmake --build . -j4 \
        && $cmake --install .)
    if [ -n "$IS_OSX" ]; then
        :
    else
        strip -v --strip-unneeded ${BUILD_PREFIX}/lib/libgdal.so.* || true
        strip -v --strip-unneeded ${BUILD_PREFIX}/lib64/libgdal.so.* || true
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
    local cmake=$(get_modern_cmake)
    suppress build_openssl
    suppress build_nghttp2
    if [ -n "$IS_OSX" ]; then
        rm /usr/local/lib/libpng* || true
    fi
    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    # Remove previously installed curl.
    rm -rf /usr/local/lib/libcurl* || true
    suppress build_curl
    suppress build_jpeg
    suppress build_jsonc
    suppress build_tiff
    suppress build_sqlite
    suppress build_proj
    suppress build_expat
    suppress build_geos
    if [ -n "$IS_OSX" ]; then
        export LDFLAGS="${LDFLAGS} -Wl,-rpath,${BUILD_PREFIX}/lib"
    fi
    suppress build_gdal
}
