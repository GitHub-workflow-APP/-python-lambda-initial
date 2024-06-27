#!/usr/bin/env bash

LAMBDA_FUNCTION_NAME=brandon-python-another
ARTIFACT_DIR=./artifacts
ARTIFACT_FILE=foobar-$(date +'%s').zip

ARTIFACT_DIR="$(realpath $ARTIFACT_DIR)"
mkdir -p "${ARTIFACT_DIR}"



pushd src
zip -r "${ARTIFACT_DIR}/${ARTIFACT_FILE}" *
popd

echo "deploying now"
if aws lambda update-function-code --function-name "${LAMBDA_FUNCTION_NAME}" --zip-file fileb://"${ARTIFACT_DIR}/${ARTIFACT_FILE}"; then
    echo "deploy successful"
else
    echo "deploy failed"
fi
