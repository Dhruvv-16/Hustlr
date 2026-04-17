#!/bin/bash
set -euo pipefail

echo "Installing admin app dependencies"
npm ci

echo "Building static export"
npm run build

echo "Preparing Vercel output directory"
rm -rf build/web
mkdir -p build/web
cp -R out/. build/web/

echo "Build complete"