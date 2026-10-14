import 'dart:convert';

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

  test('surfaces HTTP errors without hiding the status code', () async {
    final repository = RestChildProfilesRepository(
      apiClient: _client(MockClient((_) async => _jsonResponse(
            {'title': 'Unauthorized'},
            401,
          ))),
    );

    expect(
      () => repository.list(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.type, 'type', ApiFailureType.http)
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', 'Unauthorized'),
      ),
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
}
