#!/bin/bash

# Destroys an environment and tears down the associated pipeline

set -euo pipefail

: $WORKSPACE
: $ENVIRONMENT
: $CONFIGURATION
: $STAGE
: ${HTTP_PROXY:="localhost:8118"}
: ${TARGET:=gcp}
: ${FLY:=fly -t ${TARGET}}

export HTTP_PROXY=${HTTP_PROXY}

pipeline="${ENVIRONMENT}-${WORKSPACE}-deploy-emails-lambda"

${FLY} trigger-job -j ${pipeline}/destroy -w  || {
    echo "Concourse destroy job failed - resources may already be deleted"
    exit 1
}
${FLY} destroy-pipeline -p ${pipeline} --non-interactive