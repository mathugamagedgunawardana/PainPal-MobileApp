#!/usr/bin/env bash
# Wrapper: official SDK + --no-dds. For plain `flutter run`, see scripts/flutter + PATH, or .vscode/settings.json.
cd "$(dirname "$0")"

if [[ -n "${FLUTTER_ROOT:-}" && -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
  FLUTTER_BIN="${FLUTTER_ROOT}/bin/flutter"
elif [[ -x "${HOME}/development/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="${HOME}/development/flutter/bin/flutter"
elif [[ -x "${HOME}/flutter/bin/flutter" ]]; then
  FLUTTER_BIN="${HOME}/flutter/bin/flutter"
else
  FLUTTER_BIN="$(command -v flutter || true)"
fi

if [[ -z "${FLUTTER_BIN}" || ! -x "${FLUTTER_BIN}" ]]; then
  echo >&2 "No flutter executable found. Clone stable: git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter"
  exit 1
fi

case "${FLUTTER_BIN}" in
  /usr/bin/flutter|/usr/lib/flutter/bin/flutter)
    echo >&2 "warning: Using distro Flutter (${FLUTTER_BIN}). Debug attach often breaks; use ~/development/flutter or set FLUTTER_ROOT." ;;
esac

exec "${FLUTTER_BIN}" run --no-dds "$@"
