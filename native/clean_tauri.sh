#!/bin/bash
# Complete cleanup script for Tauri project

echo "Cleaning up Tauri project..."

# Clean Rust artifacts
cd src-tauri
cargo clean
echo "✓ Rust artifacts cleaned"

# Remove temporary and lock files
find . -name "*.lock" -type f -not -name "Cargo.lock" -delete
find . -name ".DS_Store" -type f -delete
find . -name "*.bak" -type f -delete
find . -name "*.tmp" -type f -delete
find . -name "*.log" -type f -delete
echo "✓ Temporary files removed"

# Return to root directory
cd ..

# Clean npm cache
if [ -d "node_modules/.cache" ]; then
  rm -rf node_modules/.cache
  echo "✓ npm cache cleaned"
fi

# Clean JavaScript build files
if [ -d "dist" ]; then
  rm -rf dist
  echo "✓ dist folder removed"
fi

echo "Cleanup completed!"