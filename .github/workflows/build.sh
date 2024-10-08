
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  # webp, zstd, xz, libtiff cause a conflict with building webp and libtiff
  # curl from brew requires zstd, use system curl
  # if php is installed, brew tries to reinstall these after installing openblas
  brew remove --ignore-dependencies webp zstd libtiff curl php
fi

echo "::group::Get code of project: $REPO_DIR"
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
	  git clone https://github.com/OSGeo/gdal.git
	  cd gdal
	  git checkout ${BUILD_COMMIT}
	  # No such file or directory for GDAL 3.6.4
	  ls swig/python
  fi
  if [[ "$REPO_DIR" == "psutil" ]]; then
	  git clone https://github.com/giampaolo/psutil.git
	  cd psutil
	  git checkout ${BUILD_COMMIT}
  fi
echo "::endgroup::"
