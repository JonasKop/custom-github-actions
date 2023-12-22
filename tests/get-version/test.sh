#!/bin/bash

set -e

if [ "$VERSION" != "$OUTPUT_VERSION" ]; then
  echo "ERROR: Expected env var version '$VERSION' to be the same as output variable '$OUTPUT_VERSION'"
  exit 1
fi

if [ "$BRANCH_NAME" == "main" ]; then
  if [ "$VERSION" != "${EXPECTED_VERSION}" ]; then
    echo "ERROR: Expected version to be '$EXPECTED_VERSION', but it was '$VERSION'"
    exit 1
  fi
elif [[ $VERSION != ${EXPECTED_VERSION}-* ]]; then
  echo "ERROR: Expected version to be '$EXPECTED_VERSION', but it was '$VERSION'"
  exit 1
fi

echo "Tests completed, success!"
