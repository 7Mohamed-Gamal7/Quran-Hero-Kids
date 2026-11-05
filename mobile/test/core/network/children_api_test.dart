import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_hero_kids/src/core/auth/token_provider.dart';
import 'package:quran_hero_kids/src/core/network/api_client.dart';
import 'package:quran_hero_kids/src/core/network/api_config.dart';
import 'package:quran_hero_kids/src/core/network/api_exception.dart';
import 'package:quran_hero_kids/src/features/children/data/children_repository.dart';
import 'package:quran_hero_kids/src/features/children/domain/child_profile.dart';

class _TokenProvider implements TokenProvider {
  @override
  Future<String?> getIdToken() async => 'test-id-token';
}

ApiClient _client(MockClient client) => ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.test'),
      tokenProvider: _TokenProvider(),
      httpClient: client,
    );

class _FailingResponseBodyClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream<List<int>>.error(const SocketException('connection reset')),
        200,
      );
}

Map<String, dynamic> _child(String id) => {
      'id': id,
      'name': 'ليان',
      'ageBand': '8-10',
      'isArchived': false,
      'createdAt': '2024-01-01T00:00:00Z',
      'updatedAt': '2024-01-01T00:00:00Z',
    };

http.Response _jsonResponse(Object body, int statusCode) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('lists children on the REST route with a Firebase bearer header',
      () async {
    late http.Request request;
    final repository = RestChildProfilesRepository(
      apiClient: _client(MockClient((incoming) async {
        request = incoming;
        return _jsonResponse([_child('child-1')], 200);
      })),
    );

    final children = await repository.list();

    expect(request.method, 'GET');
    expect(request.url.toString(), 'https://api.example.test/api/v1/children');
    expect(request.headers['authorization'], 'Bearer test-id-token');
    expect(request.headers['accept'], 'application/json');
    expect(children.single.name, 'ليان');
    expect(children.single.ageBand, '8-10');
  });

  test('uses create, update, get, and delete routes with JSON serialization',
      () async {
    final requests = <http.Request>[];
    final client = _client(MockClient((request) async {
      requests.add(request);
      if (request.method == 'DELETE') return http.Response('', 204);
      return _jsonResponse(
          _child('child-9'), request.method == 'POST' ? 201 : 200);
    }));
    final repository = RestChildProfilesRepository(apiClient: client);
    final draft = ChildProfileDraft(
      name: '  ليان  ',
      ageBand: '8-10',
    );

    await repository.create(draft);
    await repository.getById('child-9');
    await repository.update('child-9', draft);
    await repository.archive('child-9');

    expect(requests.map((request) => '${request.method} ${request.url.path}'), [
      'POST /api/v1/children',
      'GET /api/v1/children/child-9',
      'PUT /api/v1/children/child-9',
      'DELETE /api/v1/children/child-9',
    ]);
    expect(requests[0].headers['content-type'], 'application/json');
    expect(jsonDecode(requests[0].body), {
      'name': 'ليان',
      'ageBand': '8-10',
    });
    expect(requests[2].headers['authorization'], 'Bearer test-id-token');
  });

  const serverDetail = 'SqlException: /srv/private/db child=ليان';
  const safeHttpMessages = <int, String>{
    400: 'تعذر إكمال الطلب. راجع المعلومات وحاول مرة أخرى.',
    401: 'تعذر التحقق من الجلسة. يرجى المحاولة مجددًا.',
    403: 'لا تملك صلاحية تنفيذ هذا الطلب.',
    404: 'لم يتم العثور على البيانات المطلوبة.',
    409: 'تعارضت البيانات الحالية مع الطلب. حدّث البيانات ثم حاول مجددًا.',
    422: 'تعذر إكمال الطلب. راجع المعلومات وحاول مرة أخرى.',
    418: 'تعذر إكمال الطلب. حاول مرة أخرى لاحقًا.',
    500: 'الخادم غير متاح حاليًا. حاول مرة أخرى لاحقًا.',
  };
  for (final entry in safeHttpMessages.entries) {
    test('uses a safe message for HTTP ${entry.key}', () async {
      final client = _client(MockClient((_) async => _jsonResponse(
            {'title': 'Internal response', 'detail': serverDetail},
            entry.key,
          )));

      await expectLater(
        client.get('/api/v1/children'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.type, 'type', ApiFailureType.http)
              .having((error) => error.statusCode, 'statusCode', entry.key)
              .having((error) => error.message, 'message', entry.value)
              .having(
                (error) => error.message.contains(serverDetail),
                'contains server detail',
                isFalse,
              ),
        ),
      );
    });
  }

  test('maps response body stream failures to a network error', () async {
    final client = ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.test'),
      tokenProvider: _TokenProvider(),
      httpClient: _FailingResponseBodyClient(),
    );

    await expectLater(
      client.get('/api/v1/children'),
      throwsA(isA<ApiException>().having(
        (error) => error.type,
        'type',
        ApiFailureType.network,
      )),
    );
  });

  test('does not send a request when API URL or token is missing', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('[]', 200);
    });
    final missingUrl = ApiClient(
      config: const ApiConfig(baseUrl: ''),
      tokenProvider: _TokenProvider(),
      httpClient: client,
    );
    final missingToken = ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.test'),
      tokenProvider: const MissingTokenProvider(),
      httpClient: client,
    );

    await expectLater(
      missingUrl.get('/api/v1/children'),
      throwsA(isA<ApiException>().having(
        (error) => error.type,
        'type',
        ApiFailureType.configuration,
      )),
    );
    await expectLater(
      missingToken.get('/api/v1/children'),
      throwsA(isA<ApiException>().having(
        (error) => error.type,
        'type',
        ApiFailureType.authentication,
      )),
    );
    expect(calls, 0);
  });

  test('does not send a bearer token to an HTTP API URL', () async {
    var calls = 0;
    final client = ApiClient(
      config: const ApiConfig(baseUrl: 'http://api.example.test'),
      tokenProvider: _TokenProvider(),
      httpClient: MockClient((_) async {
        calls++;
        return http.Response('[]', 200);
      }),
    );

    await expectLater(
      client.get('/api/v1/children'),
      throwsA(isA<ApiException>().having(
        (error) => error.type,
        'type',
        ApiFailureType.configuration,
      )),
    );
    expect(calls, 0);
  });
}
