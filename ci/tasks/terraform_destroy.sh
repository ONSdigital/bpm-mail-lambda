#!/bin/bash

set -euo pipefail

: ${WORKSPACE}
: ${TF_VAR_stage}
: ${AWS_REGION}
: ${TF_VAR_BPM_USER}
: ${TF_VAR_BPM_PW}
: ${S3_NAME}
: ${S3_KEY}

. ./bpm-mail-lambda/ci/tasks/util/assume_role.sh
. ./bpm-mail-lambda/ci/tasks/util/setup_terraform.sh

# Generate fake deployment file to satisfy hash function
# in terraform
pushd ../../
mkdir generated
touch generated/function.zip
popd

terraform destroy --auto-approve

echo "done"