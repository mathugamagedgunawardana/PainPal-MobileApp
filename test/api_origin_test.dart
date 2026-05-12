import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:painpal/util/api_origin.dart';

void main() {
  group('normalizeApiOrigin', () {
    test('trims and strips trailing slashes', () {
      expect(normalizeApiOrigin('  https://api.example.com///  '), 'https://api.example.com');
    });

    test('handles empty', () {
      expect(normalizeApiOrigin(''), '');
      expect(normalizeApiOrigin('   '), '');
    });
  });

  group('mapAndroidLoopbackIfNeeded', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('leaves URL unchanged on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        mapAndroidLoopbackIfNeeded('http://127.0.0.1:3000'),
        'http://127.0.0.1:3000',
      );
    });

    test('maps 127.0.0.1 to 10.0.2.2 on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        mapAndroidLoopbackIfNeeded('http://127.0.0.1:3000'),
        'http://10.0.2.2:3000',
      );
    });

    test('maps localhost on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        mapAndroidLoopbackIfNeeded('http://localhost:3000/path'),
        'http://10.0.2.2:3000/path',
      );
    });
  });

  group('resolveApiOriginForDevice', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('normalizes then maps on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        resolveApiOriginForDevice(rawBase: 'http://127.0.0.1:3000/'),
        'http://10.0.2.2:3000',
      );
    });
  });
}
