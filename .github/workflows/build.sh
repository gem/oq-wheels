
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  # webp, zstd, xz, libtiff cause a conflict with building webp and libtiff
  # curl from brew requires zstd, use system curl
  # if php is installed, brew tries to reinstall these after installing openblas
  brew remove --ignore-dependencies webp zstd xz libtiff curl php
fi

echo "::group::Get code of project: $REPO_DIR"
  PATH=/opt/homebrew/opt/python@${MB_PYTHON_VERSION}/libexec/bin:$PATH
  python -c "import sys; print(sys.version)" | awk -F \. {'print $1$2'}
  source multibuild/common_utils.sh
  source multibuild/travis_steps.sh
  if [[ "$REPO_DIR" == "Fiona" ]]; then
	  git clone https://github.com/Toblerity/Fiona.git
	  cd Fiona
	  git checkout ${BUILD_COMMIT}
  fi
  if [[ "$REPO_DIR" == "pyproj" ]]; then
	  git clone https://github.com/pyproj4/pyproj.git
	  cd pyproj
	  git checkout ${BUILD_COMMIT}
  fi
  if [[ "$REPO_DIR" == "gdal" ]]; then
      pip3 download GDAL==${BUILD_COMMIT}
      tar -xvzf GDAL-${BUILD_COMMIT}.tar.gz
      mv GDAL-${BUILD_COMMIT} gdal
  fi
  if [[ "$REPO_DIR" == "Fiona" ]]; then
     clean_code $REPO_DIR $BUILD_COMMIT
  fi
echo "::endgroup::"
