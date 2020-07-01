#!/bin/bash

set -euo pipefail

: ${WORKSPACE}
: ${CONFIGURATION}
: $STAGE
: ${AWS_REGION}
: ${TF_VAR_BPM_USER}
: ${TF_VAR_BPM_PW}
: ${S3_NAME}
: ${S3_KEY}

. ./bpm-mail-lambda/ci/tasks/util/assume_role.sh
. ./bpm-mail-lambda/ci/tasks/util/setup_terraform.sh

terraform destroy --auto-approve

echo "done"