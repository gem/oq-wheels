echo "::group::Build wheel"
  source multibuild/common_utils.sh
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

echo "::group::Test wheel"
  source multibuild/common_utils.sh
  if [[ "$REPO_DIR" == "Fiona" ]]; then
      install_run $PLAT
  fi
  if [[ "$REPO_DIR" == "gdal" ]]; then
      install_run $PLAT 
  fi
echo "::endgroup::"
