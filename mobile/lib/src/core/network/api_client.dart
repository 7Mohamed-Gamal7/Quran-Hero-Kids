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
        message: 'الخدمة غير مهيأة حاليًا. يرجى المحاولة لاحقًا.',
      );
    }

    final token = (await _tokenProvider.getIdToken())?.trim();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        type: ApiFailureType.authentication,
        message: 'تعذر التحقق من الجلسة. يرجى تسجيل الدخول مجددًا.',
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
    late final String responseBody;
    try {
      response = await _httpClient.send(request);
      responseBody = await response.stream.bytesToString();
    } on Exception {
      throw ApiException(
        type: ApiFailureType.network,
        message: 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        type: ApiFailureType.http,
        statusCode: response.statusCode,
        message: ApiException.userMessageForHttpStatus(response.statusCode),
      );
    }
    if (responseBody.trim().isEmpty) return null;

    try {
      return jsonDecode(responseBody);
    } on FormatException {
      throw ApiException(
        type: ApiFailureType.decoding,
        statusCode: response.statusCode,
        message: 'تعذر قراءة استجابة الخادم. حاول مرة أخرى لاحقًا.',
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
}
