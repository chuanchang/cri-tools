#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

CRIO_REPO=github.com/kubernetes-sigs/cri-o
WORKDIR="${GOPATH}/src/${CRIO_REPO}"

# crio::check_daemon_listening checks whether daemon is listening
crio::check_daemon_listening() {
  local has_listened crio_sock
  crio_sock="/var/run/crio/crio.sock"

  has_listened="$(netstat -lx | grep ${crio_sock} || echo false)"
  if [[ "${has_listened}" = "false" ]]; then
    echo false
    exit 0
  fi

  echo true
}

# crio::check_seccomp_conf checks whether /etc/crio/seccomp.json exists
crio::check_seccomp_conf() {
  local has_existed seccomp_conf fpath
  seccomp_conf="/etc/crio/seccomp.json"

  if [[ -f "${seccomp_conf}" ]]; then
    echo true
    exit 0
  fi

  fpath="https://raw.githubusercontent.com/kubernetes-sigs/cri-o/master/seccomp.json"
  sudo wget -P /etc/crio ${fpath}

  if [[ -f "${seccomp_conf}" ]]; then
    echo true
    exit 0
  fi

  echo false
}

# crio:run starts crio daemon with metrics and selinux enabled
crio::run() {
  local cri_runtime tmplog_dir crio_log flags

  tmplog_dir="$(mktemp -d /tmp/integration-cri-testing-XXXXX)"
  crio_log="${tmplog_dir}/crio.log"
  echo ">>>> crio log: ${crio_log} <<<<"
  flags="--log-level debug"

  crio ${flags} > ${crio_log} 2>&1 &

  # Wait a while for crio daemon starting
  sleep 10
}

main() {
  local cri_runtime crio_has_listened

  if [[ "$(crio::check_seccomp_conf)" = "false" ]]; then
    echo "/etc/crio/seccomp.json doesn't exist!!"
    exit 1
  fi

  crio_has_listened="$(crio::check_daemon_listening)"
	  
  if [[ "${crio_has_listened}" = "true" ]]; then
    echo "crio have been listened."
    exit 0
  fi

  crio::run

  crio_has_listened="$(crio::check_daemon_listening)"

  if [[ "${crio_has_listened}" = "false" ]]; then
    echo "crio has not been listened: $(netstat -lx)"
    exit 1
  fi

  exit 0
}

main "$@"
