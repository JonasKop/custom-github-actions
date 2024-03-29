#!/bin/bash

set -e

# Get PR source branch if exists, otherwise use current branch
branch=${GITHUB_HEAD_REF:-$GITHUB_REF_NAME}

# Get the latest tag
latest_version=$(git describe --tags --abbrev=0 || :)

# If no tag exists, set the version to 0.0.0
if [ -z "$latest_version" ]; then
  version="0.0.0"
  echo "No previous version exists, creating a new one: ${version}"
else
  # Extract the major, minor, and patch versions
  version_parts=(${latest_version//./ })
  major=${version_parts[0]}
  minor=${version_parts[1]}
  patch=${version_parts[2]}
  echo "Latest version is $latest_version"

  newMajor="$major"
  newMinor="$minor"
  newPatch="$patch"

  # If on main, increment the minor version
  current_commit_tag=$(git describe --tags --exact-match HEAD || :)
  if [ "${current_commit_tag}" == "${latest_version}" ]; then
    echo "This commit is already tagged with ${latest_version}, skipping increment"
  elif [ "${branch}" == "main" ]; then
    # By default, increment the minor and set patch to 0
    newMinor=$((minor + 1))
    newPatch=0

    # Get latest commit message and check if it ends with something like (#123)
    commitMessage=$(git log -1 --pretty=%B)
    if [[ "$commitMessage" =~ .*\(\#[0-9]+\) ]]; then
      echo "The commit originated from a PR, checking if it was a bug..."

      # Get PR number from commit message
      export PR_NUMBER=$(echo "$commitMessage" | sed 's/^.*#//' | sed 's/).*$//')

      # Check if the PR has a bug label
      prIsBug=$(gh pr list --state all --json number,labels | yq '.[] | select(.number == env(PR_NUMBER)) | .labels | any_c(.name == "bug")')
      if [ "$prIsBug" == "true" ]; then
        echo "The commit is a bugix, incrementing patch"

        # Increment patch
        newMinor="$minor"
        newPatch=$((patch + 1))
      fi
    fi
  fi

  version="${newMajor}.${newMinor}.${newPatch}"
  echo "Version is now $version"
fi

# If not on main, add a hash suffix
if [ "${branch}" != "main" ]; then
  hash_suffix=$(git rev-parse --short=8 HEAD)
  version="${version}-${hash_suffix}"
fi

echo "Final version: ${version}"

# Set variables
echo "VERSION=$version" >>"${GITHUB_ENV}"
echo "version=$version" >>"${GITHUB_OUTPUT}"
