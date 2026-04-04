#!/bin/bash
set -e

echo "=== Installing Flutter ==="
if [ -d "flutter" ]; then
  echo "Flutter already cached, pulling latest"
  cd flutter && git pull && cd ..
else
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable
fi

export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Enabling Flutter web ==="
flutter config --enable-web
flutter --version

echo "=== Getting dependencies ==="
cd .
flutter pub get

echo "=== Building Flutter web ==="
flutter build web --release --no-sound-null-safety 2>/dev/null || flutter build web --release

echo "=== Build complete ==="
ls -la build/web/
