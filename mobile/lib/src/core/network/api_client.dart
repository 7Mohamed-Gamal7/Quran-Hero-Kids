import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/token_provider.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required ApiConfig config,
    required TokenProvider tokenProvider,
    required http.Client httpClient,
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _httpClient = httpClient;

  final ApiConfig _config;
  final TokenProvider _tokenProvider;
  final http.Client _httpClient;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, Map<String, Object?> body) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Map<String, Object?> body) =>
      _send('PUT', path, body: body);

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    if (!_config.isConfigured) {
      throw const ApiException(
        type: ApiFailureType.configuration,
        message: 'عنوان API غير مهيأ. شغّل التطبيق مع API_BASE_URL.',
      );
    }

    final token = (await _tokenProvider.getIdToken())?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        type: ApiFailureType.authentication,
        message: 'لم يتم توفير Firebase ID token.',
      );
    }

    final request = http.Request(method, _buildUri(path))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.StreamedResponse response;
    try {
      response = await _httpClient.send(request);
    } on Exception catch (error) {
      throw ApiException(
        type: ApiFailureType.network,
        message: 'تعذر الاتصال بالخادم: $error',
      );
    }

    final responseBody = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        type: ApiFailureType.http,
        statusCode: response.statusCode,
        message: _errorMessage(responseBody, response.statusCode),
      );
    }
    if (responseBody.trim().isEmpty) return null;

    try {
      return jsonDecode(responseBody);
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiFailureType.decoding,
        statusCode: response.statusCode,
        message: 'استجابة الخادم ليست JSON صالحًا: $error',
      );
    }
  }

  Uri _buildUri(String path) {
    final base = _config.uri;
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final suffix = path.startsWith('/') ? path : '/$path';
    return base.replace(path: '$basePath$suffix', query: null, fragment: null);
  }

  String _errorMessage(String body, int statusCode) {
    if (body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final detail =
              decoded['detail'] ?? decoded['title'] ?? decoded['message'];
          if (detail is String && detail.isNotEmpty) return detail;
        }
      } on FormatException {
        // Fall through to a stable status-based message.
      }
    }
    return 'فشل الطلب (HTTP $statusCode).';
  }
}
