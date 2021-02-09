#!/bin/bash

# Runs a `terraform apply` on ${TERRAFORM_SOURCE}

set -euo pipefail

: ${WORKSPACE}
: ${TF_VAR_environment}
: ${TERRAFORM_SOURCE}
: ${TF_VAR_BPM_USER}
: ${TF_VAR_BPM_PW}
: ${AWS_REGION}
: ${S3_NAME}
: ${S3_KEY}

. ./bpm-mail-lambda/ci/tasks/util/assume_role.sh
. ./bpm-mail-lambda/ci/tasks/util/setup_terraform.sh

terraform apply \
    --auto-approve
echo "done"