#!/usr/bin/env bash

S3_BUCKET_NAME=brandon-lambda-useast1
S3_KEY_DIR=lambda/python-lambda-shellscript
LAMBDA_FUNCTION_NAME=brandon-python-demo
ARTIFACT_DIR=./artifacts
ARTIFACT_FILE=foobar-$(date +'%s').zip

S3_KEY="$S3_KEY_DIR/${ARTIFACT_FILE}"
ARTIFACT_DIR="$(realpath $ARTIFACT_DIR)"
mkdir -p "${ARTIFACT_DIR}"



pushd src
zip -r "${ARTIFACT_DIR}/${ARTIFACT_FILE}" *
popd

if aws s3 cp "${ARTIFACT_DIR}/${ARTIFACT_FILE}" "s3://${S3_BUCKET_NAME}/${S3_KEY}"; then 
    echo "copied to s3 bucket; deploying now"
    if aws lambda update-function-code --function-name "${LAMBDA_FUNCTION_NAME}" --s3-bucket "${S3_BUCKET_NAME}" --s3-key "${S3_KEY}"; then
        echo "deploy successful"
    else
        echo "deploy failed"
    fi
else
    echo "ERROR: couldn't copy to s3"
fi
