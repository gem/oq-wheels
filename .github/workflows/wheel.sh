echo "::group::Build wheel"
  PATH=/opt/homebrew/opt/python@${MB_PYTHON_VERSION}/libexec/bin:$PATH
  python -c "import sys; print(sys.version)" | awk -F \. {'print $1$2'}
  source multibuild/common_utils.sh
  source multibuild/travis_steps.sh
  build_wheel $REPO_DIR $PLAT
  ls -l "${GITHUB_WORKSPACE}/${WHEEL_SDIR}/"
echo "::endgroup::"

echo "::group::Test wheel"
  PATH=/opt/homebrew/opt/python@${MB_PYTHON_VERSION}/libexec/bin:$PATH
  source multibuild/common_utils.sh
  echo $PIP_CMD
  echo $PYTHON_EXE
  if [[ "$REPO_DIR" == "Fiona" ]]; then
      install_run $PLAT
  fi
echo "::endgroup::"
