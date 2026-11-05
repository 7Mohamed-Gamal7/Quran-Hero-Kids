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
    late final String responseBody;
    try {
      response = await _httpClient.send(request);
      responseBody = await response.stream.bytesToString();
    } on Exception catch (error) {
      throw ApiException(
        type: ApiFailureType.network,
        message: 'تعذر الاتصال بالخادم: $error',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        type: ApiFailureType.http,
        statusCode: response.statusCode,
        message: _errorMessage(response.statusCode),
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

  String _errorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'تعذر إكمال الطلب. راجع المعلومات وحاول مرة أخرى.';
      case 401:
        return 'تعذر التحقق من الجلسة. يرجى المحاولة مجددًا.';
      case 403:
        return 'لا تملك صلاحية تنفيذ هذا الطلب.';
      case 404:
        return 'لم يتم العثور على البيانات المطلوبة.';
      case 409:
        return 'تعارضت البيانات الحالية مع الطلب. حدّث البيانات ثم حاول مجددًا.';
      default:
        if (statusCode >= 500) {
          return 'الخادم غير متاح حاليًا. حاول مرة أخرى لاحقًا.';
        }
        return 'تعذر إكمال الطلب. حاول مرة أخرى لاحقًا.';
    }
  }
}
