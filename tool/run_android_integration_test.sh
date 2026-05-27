#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${APP_ROOT}"

printf '%s\n' 'Prerequisite: API server is reachable at http://103.149.86.25:3000/api or override API_BASE_URL in .env.'
flutter devices

DEVICE_ID="${1:-}"
if [[ -z "${DEVICE_ID}" ]]; then
  printf '%s\n' 'Usage: ./tool/run_android_integration_test.sh <android-emulator-id>'
  exit 2
fi

flutter test integration_test/onboarding_flow_test.dart -d "${DEVICE_ID}"
