#!/bin/bash
# Run from repo root (used by Vercel). Keeps build at top level so the path is obvious in Git.
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
flutter pub get

# Point the web app at your Render (or other) Node API. Required for production web builds.
DART_DEFINES=()
if [ -n "${HUSTLR_API_PROD:-}" ]; then
  DART_DEFINES+=(--dart-define="HUSTLR_API_PROD=${HUSTLR_API_PROD}")
  echo "=== HUSTLR_API_PROD is set (web will use Render/cloud API) ==="
else
  echo "WARNING: HUSTLR_API_PROD is empty — set it in Vercel → Environment Variables (Production/Preview)." >&2
fi

if [ "${VERCEL_ENV:-}" = "production" ] && [ -z "${HUSTLR_API_PROD:-}" ]; then
  echo "ERROR: Production deploy on Vercel requires HUSTLR_API_PROD=https://your-hustlr-api.onrender.com" >&2
  exit 1
fi

echo "=== Building Flutter web ==="
flutter build web --release "${DART_DEFINES[@]}"

echo "=== Build complete ==="
ls -la build/web/
