#!/bin/bash

# Sets up a new deployment pipeline
# Make sure to set the correct environment variable (dev, preprod or prod)

set -euo pipefail

: $BRANCH
: $ENVIRONMENT
: ${AWS_REGION:="eu-west-2"}
: ${HTTP_PROXY:="localhost:8118"}
: ${TARGET:=gcp}
: ${FLY:=fly -t ${TARGET}}
: ${EXTRA_OPTIONS:=""}

export HTTP_PROXY=${HTTP_PROXY}

WORKSPACE=`echo "${BRANCH:0:13}" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]'`
pipeline="${ENVIRONMENT}-${WORKSPACE}-deploy-emails-lambda"

${FLY} set-pipeline \
    -p ${pipeline} \
    -c ci/pipeline.yml \
    -v "workspace=${WORKSPACE}" \
    -v "aws_region=${AWS_REGION}" \
    -v "environment=${ENVIRONMENT}" \
    -v "branch=${BRANCH}" \
    ${EXTRA_OPTIONS}

${FLY} unpause-pipeline \
    -p ${pipeline}