import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hero_kids/src/core/network/api_config.dart';

void main() {
  test('accepts an HTTPS API base URL', () {
    const config = ApiConfig(baseUrl: 'https://api.example.test/v1');

    expect(config.isConfigured, isTrue);
    expect(config.uri.toString(), 'https://api.example.test/v1');
  });

  test('rejects HTTP because API requests may carry bearer tokens', () {
    const config = ApiConfig(baseUrl: 'http://api.example.test');

    expect(config.isConfigured, isFalse);
    expect(() => config.uri, throwsFormatException);
  });

  test('rejects missing, relative, and non-HTTP(S) URLs', () {
    for (final baseUrl in ['', '/api', 'ftp://api.example.test']) {
      expect(ApiConfig(baseUrl: baseUrl).isConfigured, isFalse);
    }
  });
}
