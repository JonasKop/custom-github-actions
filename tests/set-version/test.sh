#!/bin/bash

set -e

commitTags=$(git tag --points-at HEAD)
if [ -z "$commitTags" ]; then
  echo "ERROR: No tags exists on this commit."
  exit 1
fi

found=false
for tag in $commitTags; do
  if [ "$tag" == "$VERSION" ]; then
    found=true
    break
  fi
done

if [ "$found" == "false" ]; then
  echo "ERROR: Did not find a matching tag. Expected to find $VERSION in '$commitTags'"
  exit 1
fi

echo "Tests completed, success!"
