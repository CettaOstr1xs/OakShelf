import 'dart:io';
import 'dart:convert';

String getLocalSecretsToken() {
  try {
    final file = File('secrets.json');
    if (file.existsSync()) {
      final json = jsonDecode(file.readAsStringSync());
      return json['HARDCOVER_API_TOKEN'] ?? '';
    }
  } catch (_) {}
  return '';
}
