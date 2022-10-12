echo "::group::Build wheel"
  echo "check python of venv"
  which python
  python -c "import sys; print(sys.version)" | awk -F \. {'print $1$2'}
  echo $PIP_CMD
  echo $PYTHON_EXE
  source multibuild/common_utils.sh
  source multibuild/travis_steps.sh
  build_wheel $REPO_DIR $PLAT
  ls -l "${GITHUB_WORKSPACE}/${WHEEL_SDIR}/"
echo "::endgroup::"

echo "::group::Test wheel"
  source multibuild/common_utils.sh
  if [[ "$REPO_DIR" == "Fiona" ]]; then
      install_run $PLAT
  fi
echo "::endgroup::"
