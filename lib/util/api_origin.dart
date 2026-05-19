import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Trims and removes trailing slashes from an API origin.
String normalizeApiOrigin(String raw) {
  var s = raw.trim();
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// On Android emulator, `localhost` / `127.0.0.1` refer to the emulator, not the host.
String mapAndroidLoopbackIfNeeded(String base) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return base;
  }
  final parsed = Uri.tryParse(base);
  if (parsed == null || !parsed.hasAuthority) {
    return base;
  }
  if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
    return parsed.replace(host: '10.0.2.2').toString();
  }
  return base;
}

/// Normalizes then applies Android emulator host mapping.
///
/// When [skipAndroidLoopbackMap] is true (`.env` `API_ANDROID_USE_LOCALHOST=true`),
/// keep `localhost` / `127.0.0.1` unchanged. You must run
/// `adb reverse tcp:3000 tcp:3000` so the emulator's loopback reaches the host.
String resolveApiOriginForDevice({
  required String rawBase,
  bool skipAndroidLoopbackMap = false,
}) {
  final normalized = normalizeApiOrigin(rawBase);
  if (skipAndroidLoopbackMap) {
    return normalized;
  }
  return mapAndroidLoopbackIfNeeded(normalized);
}
