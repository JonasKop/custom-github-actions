#!/usr/bin/env python3

import os, subprocess

# Get environment variables
images = os.environ["CONTAINER_IMAGES"]
charts = os.environ["HELM_CHARTS"]
repositoryOwner = os.environ["GITHUB_REPOSITORY_OWNER"].lower()

# Get version from en var if exist, else use latest commit to get version
version = os.environ.get("VERSION")
if not version:
    version = (
        subprocess.check_output(["git", "describe", "--tags", "--exact-match"])
        .decode("utf-8")
        .strip()
    )

# Get all previous tags preceeding this commit
previousCommit = subprocess.check_output(
    ["git", "rev-list", version, "--skip=1", "--max-count=1"]
).decode("utf-8")

try:
    # Get previous version
    previousVersion = subprocess.check_output(
        ["git", "describe", "--abbrev=0", "--tags", previousCommit]
    )
    commitInterval = f"{previousVersion}..{version}"
except subprocess.CalledProcessError as e:
    commitInterval = version

# Get commitmessages since last tag
rawCommitMessages = subprocess.check_output(
    ["git", "log", commitInterval, "--pretty=format:%s"]
).decode("utf-8")

# Add a "- " prefix on each commit message
commitMessages = "\n".join(f"- {msg}" for msg in rawCommitMessages.splitlines())

# Generate docker pull command for each image
imagesMessage = "\n".join(
    f"docker pull ghcr.io/{repositoryOwner}/{image}:{version}"
    for image in images.split()
)

# Generate helm pull command for each chart
chartsMessage = "\n".join(
    f"helm pull oci://ghcr.io/{repositoryOwner}/helm/{chart} --version {version}"
    for chart in charts.split()
)

# Create changelog
changelog = f"""
## Commits
{commitMessages}
"""

# If images exists, add to changelog
if images:
    changelog += f"""
## Container images
```bash
{imagesMessage}
```
"""

# If charts exists, add to changelog
if charts:
    changelog += f"""
## Helm charts
```bash
{chartsMessage}
```
"""

# Set version
f = open(os.environ["GITHUB_ENV"], "a")
f.write(f"RELEASE_VERSION={version}")
f.close()


# Remove trailing whitespace and write changelog to file
changelog = changelog.strip()
f = open(os.environ["CHANGELOG_FILE"], "w")
f.write(changelog)
f.close()
