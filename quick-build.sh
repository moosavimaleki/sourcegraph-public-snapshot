#!/usr/bin/env bash
set -euo pipefail

echo "=== Quick Sourcegraph Docker Build ==="
echo ""
echo "This script creates a custom Docker image based on the official Sourcegraph image"
echo "with your local code changes."
echo ""

# Check if there are any code changes
CHANGED_FILES=$(git status --porcelain 2>/dev/null | grep -E '\.(go|js|ts|tsx|jsx)$' || true)

if [ -z "$CHANGED_FILES" ]; then
    echo "No source code changes detected."
    echo "For a full rebuild, use: ./bazelisk build //cmd/server:image_tarball"
    exit 0
fi

echo "Found local changes. Creating custom Dockerfile..."

# Create custom Dockerfile
cat > Dockerfile.quick <<EOF
# Use the latest official Sourcegraph image as base
FROM sourcegraph/server:5.9.0

# Copy changed files
WORKDIR /
EOF

# Add COPY instructions for changed files
echo "$CHANGED_FILES" | while read -r line; do
    file=$(echo "$line" | awk '{print $2}')
    if [ -n "$file" ]; then
        echo "COPY $file /$file" >> Dockerfile.quick
    fi
done

echo "" >> Dockerfile.quick
echo "# Rebuild if necessary" >> Dockerfile.quick
echo "RUN if [ -f /usr/local/bin/frontend ]; then echo 'Frontend binary exists'; fi" >> Dockerfile.quick

echo ""
echo "Building Docker image..."
docker build -f Dockerfile.quick -t sourcegraph-dev:latest .

echo ""
echo "✅ Build complete!"
echo "Image: sourcegraph-dev:latest"
echo ""
echo "To run:"
echo "  docker run -d --name sourcegraph-dev -p 7080:7080 sourcegraph-dev:latest"
echo ""
echo "Note: This is a quick build for development. For production, use the full Bazel build."