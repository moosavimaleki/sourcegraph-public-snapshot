#!/usr/bin/env bash
set -euo pipefail

echo "=== Monitoring Bazel Build Progress ==="
echo ""
echo "Current build command: bazel build //cmd/server:image_tarball"
echo ""

# Check if bazel is running
if pgrep -f "bazel.*server:image_tarball" > /dev/null; then
    echo "✓ Build is in progress..."
    echo ""
    
    # Show bazel output directory size
    if [ -d "$HOME/.cache/bazel" ]; then
        echo "Bazel cache size: $(du -sh $HOME/.cache/bazel 2>/dev/null | cut -f1)"
    fi
    
    # Check for any recent logs
    echo ""
    echo "Recent activity:"
    tail -n 20 bazel-build.log 2>/dev/null || echo "(No log file found)"
    
else
    echo "⚠️  No active bazel build found for server:image_tarball"
    echo ""
    echo "To start the build, run:"
    echo "  ./bazelisk build //cmd/server:image_tarball"
fi

echo ""
echo "Tip: The first build will take 30-60 minutes as it downloads and compiles all dependencies."
echo "Subsequent builds will be much faster due to Bazel's caching."