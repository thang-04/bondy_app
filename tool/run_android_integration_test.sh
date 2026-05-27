#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${APP_ROOT}"

printf '%s\n' 'Prerequisite: start backend from ../bondy_server with npm run dev; Android emulator reaches it through http://10.0.2.2:3000/api.'
flutter devices

DEVICE_ID="${1:-}"
if [[ -z "${DEVICE_ID}" ]]; then
  printf '%s\n' 'Usage: ./tool/run_android_integration_test.sh <android-emulator-id>'
  exit 2
fi

flutter test integration_test/onboarding_flow_test.dart -d "${DEVICE_ID}"
