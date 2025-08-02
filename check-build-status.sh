#!/usr/bin/env bash
set -euo pipefail

echo "=== Checking Sourcegraph Build Status ==="
echo ""

# Check if bazel is running
if pgrep -f "bazel.*server:image_tarball" > /dev/null; then
    echo "✓ Bazel build is still in progress..."
    
    # Get process info
    BAZEL_PID=$(pgrep -f "bazel.*server:image_tarball" | head -1)
    echo "  Process ID: $BAZEL_PID"
    
    # Get CPU usage
    CPU_USAGE=$(ps -p $BAZEL_PID -o %cpu | tail -1)
    echo "  CPU Usage: $CPU_USAGE%"
    
    # Get memory usage
    MEM_USAGE=$(ps -p $BAZEL_PID -o %mem | tail -1)
    echo "  Memory Usage: $MEM_USAGE%"
    
    echo ""
    echo "⏳ Build is still running. This can take 30-60 minutes for the first build."
else
    echo "❌ No active bazel build found."
fi

echo ""
echo "=== Checking for completed artifacts ==="

# Check for completed tarball
if [ -f "bazel-bin/cmd/server/tarball.tar" ]; then
    echo "✅ Image tarball found!"
    ls -lh bazel-bin/cmd/server/tarball.tar
elif [ -f "bazel-bin/cmd/server/image.tar" ]; then
    echo "✅ Image tar found!"
    ls -lh bazel-bin/cmd/server/image.tar
else
    echo "⏳ No completed image tarball found yet."
fi

# Check Docker images
echo ""
echo "=== Docker Images ==="
if command -v docker &> /dev/null && docker ps &> /dev/null 2>&1; then
    docker images | grep -E "(server|sourcegraph)" | head -5 || echo "No Sourcegraph images found"
else
    echo "Docker requires sudo. Run: sudo docker images | grep server"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Wait for build to complete"
echo "2. Run: ./bazelisk run //cmd/server:image_tarball"
echo "3. Or use quick-build.sh for faster testing"