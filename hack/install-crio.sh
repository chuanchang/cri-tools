#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

CRIO_BRANCH="master"
CRIO_REPO=github.com/kubernetes-sigs/cri-o
WORKDIR="${GOPATH}/src/${CRIO_REPO}"

# crio::check_install checks whether crio command has been installed.
crio::check_install() {
  local has_installed

  has_installed="$(command -v crio || echo false)"
  if [[ "${has_installed}" = "false" ]]; then
    echo false
    exit 0
  fi

  echo true
}

# crio::version returns current crio version
crio::version() {
  local version
  version="$(crio --version | grep commit | cut -d ":" -f2 | sed "s/\"//g")"

  echo $version
}

# crio::install downloads repo and build.
crio::install() {
  if [ ! -d "${WORKDIR}" ]; then
    mkdir -p "${WORKDIR}"
    cd "${WORKDIR}"
    git clone -b ${CRIO_BRANCH} https://${CRIO_REPO} .
  fi

  cd "${WORKDIR}"
  git fetch --all
  if [[ "${CRIO_BRANCH}" != "master" ]]; then
    git checkout ${CRIO_BRANCH}
  fi

  make install.tools
  TEST_FLAGS= BUILDTAGS="selinux seccomp apparmor" make
  sudo env "PATH=$PATH" make install
  cd -
}

main() {
  local has_installed

  has_installed="$(crio::check_install)"
  if [[ "${has_installed}" = "true" ]]; then
	  echo "crio binary has been installed: $(command -v crio)"
    exit 0
  fi

  echo ">>>>  install crio-$(crio::version)  <<<<"
  crio::install

  command -v crio > /dev/null
}

main "$@"

