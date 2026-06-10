echo "::group::Build wheel"
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
#  # webp, zstd, xz, libtiff cause a conflict with building webp and libtiff
#  # curl from brew requires zstd, use system curl
#  # if php is installed, brew tries to reinstall these after installing openblas
#  brew remove --ignore-dependencies zstd libtiff curl php
   echo "Wheels for OSX"
   source multibuild/osx_utils.sh
  else
   echo "Wheels for ManyLinux"
   source multibuild/manylinux_utils.sh
fi
  source multibuild/travis_steps.sh
  before_install
  echo "+++++++++++++++++++++++++++++++++++++++++"
  echo "check python of venv after before_install"
  echo "+++++++++++++++++++++++++++++++++++++++++"
  which python
  python3 -c "import sys; print(sys.version)" | awk -F \. {'print $1$2'}
  echo $PIP_CMD
  echo $PYTHON_EXE
  echo $REPO_DIR
  echo $PLAT
  echo " ${PROJ_DIR}  ${PROJ_DATA}"
  echo " ${PROJ_WHEEL} ${PROJ_NETWORK}"
  build_wheel $REPO_DIR $PLAT
  ls -l "${GITHUB_WORKSPACE}/${WHEEL_SDIR}/"
echo "::endgroup::"
