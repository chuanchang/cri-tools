#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# CRI_SKIP skips the test to skip.
DEFAULT_CRI_SKIP="runtime should support portforward"
DEFAULT_CRI_SKIP="${DEFAULT_CRI_SKIP}|runtime should support port mapping with host port and container port "
DEFAULT_CRI_SKIP="${DEFAULT_CRI_SKIP}|runtime should support portforward in host network"
DEFAULT_CRI_SKIP="${DEFAULT_CRI_SKIP}|runtime should support port mapping with only container port"
CRI_SKIP="${CRI_SKIP:-"${DEFAULT_CRI_SKIP}"}"

# CRI_FOCUS focuses the test to run.
# With the CRI manager completes its function, we may need to expand this field.
CRI_FOCUS=${CRI_FOCUS:-}

CRIO_SOCK="/var/run/crio/crio.sock"

# tmplog_dir stores the background job log data
tmplog_dir="$(mktemp -d /tmp/integration-daemon-cri-testing-XXXXX)"
critest_log="${tmplog_dir}/critest.log"
trap 'rm -rf /tmp/integration-daemon-cri-testing-*' EXIT

# Run e2e test cases
critest::run_e2e() {
    critest --runtime-endpoint=${CRIO_SOCK} \
      --ginkgo.focus="${CRI_FOCUS}" --ginkgo.skip="${CRI_SKIP}"

    code=$?

    if [[ "${code}" != "0" ]]; then
        echo "failed to pass cri e2e cases!"
        echo "there is daemon logs..."
        cat "${critest_log}"
        exit ${code}
    fi
}

main() {
    critest::run_e2e
}

main "$@"

