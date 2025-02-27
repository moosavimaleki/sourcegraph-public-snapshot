#!/usr/bin/env bash

set -euo pipefail

# Build a standalone Docker image similar to sourcegraph/server with license restrictions bypassed

echo "Building Sourcegraph standalone server image..."

# Set image name and tag
IMAGE_NAME="sourcegraph-unlimited"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Ensure we're in the repository root
cd "$(dirname "${BASH_SOURCE[0]}")"

# Step 1: Build all the necessary components using Bazel
echo "Building components with Bazel..."

# Build the server binary and all dependencies
bazel build //cmd/server:image_tarball

# Load the image into Docker
echo "Loading image into Docker..."
docker load < bazel-bin/cmd/server/image_tarball/tarball.tar

# Tag the image with our custom name
docker tag server:candidate ${FULL_IMAGE_NAME}

echo "Successfully built ${FULL_IMAGE_NAME}"
echo "You can run the image with: docker run -p 7080:7080 -p 3370:3370 ${FULL_IMAGE_NAME}"
echo "Then access Sourcegraph at http://localhost:7080"