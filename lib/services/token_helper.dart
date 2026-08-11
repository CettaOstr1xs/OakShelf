import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'token_helper_fallback.dart'
    if (dart.library.io) 'token_helper_io_fallback.dart';

Future<String> getHardcoverToken() async {
  // 1. Try from environment (compiled flag)
  const envToken = String.fromEnvironment(
    'HARDCOVER_API_TOKEN',
    defaultValue: '',
  );
  if (envToken.isNotEmpty) return envToken;

  // 2. Try loading secrets.json from local filesystem (for local tests)
  final localToken = getLocalSecretsToken();
  if (localToken.isNotEmpty) return localToken;

  // 3. Try loading secrets.json from bundled assets
  try {
    final content = await rootBundle.loadString('secrets.json');
    final json = jsonDecode(content);
    final token = json['HARDCOVER_API_TOKEN'];
    if (token != null && token.toString().isNotEmpty) {
      return token.toString();
    }
  } catch (_) {}

  return '';
}
