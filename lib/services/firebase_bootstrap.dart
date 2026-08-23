import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../firebase_options.dart';

/// Resolves [FirebaseOptions] for the current platform at runtime.
///
/// The generated `firebase_options.dart` reads its values from compile-time
/// `--dart-define` variables. Launching the app without those defines (for
/// example by pressing Run in the IDE) silently produced empty API keys,
/// which made every Firestore stream return an empty library.
///
/// This loader prefers any non-empty dart-define value and falls back to the
/// matching key in the bundled `secrets.json` asset, so a plain
/// `flutter run` boots with a fully configured Firebase app.
class FirebaseBootstrap {
  static Future<FirebaseOptions> resolveOptions() async {
    final secrets = await _loadSecrets();
    try {
      final base = DefaultFirebaseOptions.currentPlatform;
      return _fillFromSecrets(base, secrets);
    } on UnsupportedError {
      throw UnsupportedError(
        'No Firebase configuration available for this platform.',
      );
    }
  }

  static Future<Map<String, String>> _loadSecrets() async {
    try {
      final raw = await rootBundle.loadString('secrets.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
    } catch (e) {
      debugPrint('FirebaseBootstrap: secrets.json unavailable: $e');
    }
    return const {};
  }

  static String get _prefix {
    if (kIsWeb) return 'FIREBASE_WEB_';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'FIREBASE_ANDROID_';
      case TargetPlatform.iOS:
        return 'FIREBASE_IOS_';
      case TargetPlatform.macOS:
        return 'FIREBASE_MACOS_';
      case TargetPlatform.windows:
        return 'FIREBASE_WINDOWS_';
      default:
        return '';
    }
  }

  static FirebaseOptions _fillFromSecrets(
    FirebaseOptions base,
    Map<String, String> secrets,
  ) {
    String? pick(String suffix) {
      final fromDefine = _fieldFor(suffix, base);
      if (fromDefine != null && fromDefine.isNotEmpty) return fromDefine;
      return secrets['$_prefix$suffix'];
    }

    return base.copyWith(
      apiKey: _nonEmpty(pick('API_KEY'), base.apiKey),
      appId: _nonEmpty(pick('APP_ID'), base.appId),
      messagingSenderId:
          _nonEmpty(pick('MESSAGING_SENDER_ID'), base.messagingSenderId),
      projectId: _nonEmpty(pick('PROJECT_ID'), base.projectId),
      storageBucket: _nonEmpty(pick('STORAGE_BUCKET'), base.storageBucket),
      authDomain: _nonEmpty(pick('AUTH_DOMAIN'), base.authDomain),
      measurementId: _nonEmpty(pick('MEASUREMENT_ID'), base.measurementId),
      iosBundleId: _nonEmpty(pick('BUNDLE_ID'), base.iosBundleId),
    );
  }

  static String? _nonEmpty(String? candidate, String? fallback) {
    if (candidate != null && candidate.isNotEmpty) return candidate;
    return fallback;
  }

  static String? _fieldFor(String suffix, FirebaseOptions o) {
    switch (suffix) {
      case 'API_KEY':
        return o.apiKey;
      case 'APP_ID':
        return o.appId;
      case 'MESSAGING_SENDER_ID':
        return o.messagingSenderId;
      case 'PROJECT_ID':
        return o.projectId;
      case 'STORAGE_BUCKET':
        return o.storageBucket;
      case 'AUTH_DOMAIN':
        return o.authDomain;
      case 'MEASUREMENT_ID':
        return o.measurementId;
      case 'BUNDLE_ID':
        return o.iosBundleId;
      default:
        return '';
    }
  }
}
