#!/usr/bin/env bash
# Forward emulator localhost:3000 → host localhost:3000 (pairs with API_ANDROID_USE_LOCALHOST=true).
set -euo pipefail
if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install Android platform-tools." >&2
  exit 1
fi
adb reverse tcp:3000 tcp:3000
echo "OK: emulator http://127.0.0.1:3000 → host http://127.0.0.1:3000"
echo "Start Next.js: cd ../LLM/client && npm run dev"
