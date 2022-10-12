echo "::group::Build wheel"
  source multibuild/common_utils.sh
  source multibuild/travis_steps.sh
  before_install
  echo "+++++++++++++++++++++++++++++++++++++++++"
  echo "check python of venv after before_install"
  echo "+++++++++++++++++++++++++++++++++++++++++"
  which python
  python -c "import sys; print(sys.version)" | awk -F \. {'print $1$2'}
  echo $PIP_CMD
  echo $PYTHON_EXE
  build_wheel $REPO_DIR $PLAT
  ls -l "${GITHUB_WORKSPACE}/${WHEEL_SDIR}/"
echo "::endgroup::"

echo "::group::Test wheel"
  source multibuild/common_utils.sh
  if [[ "$REPO_DIR" == "Fiona" ]]; then
      install_run $PLAT
  fi
echo "::endgroup::"
