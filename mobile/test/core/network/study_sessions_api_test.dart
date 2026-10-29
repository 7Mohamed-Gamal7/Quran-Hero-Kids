import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_hero_kids/src/core/auth/token_provider.dart';
import 'package:quran_hero_kids/src/core/network/api_client.dart';
import 'package:quran_hero_kids/src/core/network/api_config.dart';
import 'package:quran_hero_kids/src/features/study/data/study_sessions_repository.dart';
import 'package:quran_hero_kids/src/features/study/domain/study_session.dart';

class _TokenProvider implements TokenProvider {
  @override
  Future<String?> getIdToken() async => 'test-id-token';
}

ApiClient _client(http.Client client) => ApiClient(
      config: const ApiConfig(baseUrl: 'https://api.example.test'),
      tokenProvider: _TokenProvider(),
      httpClient: client,
    );

const _eventId = '123e4567-e89b-42d3-a456-426614174001';
const _childId = '123e4567-e89b-42d3-a456-426614174002';

Map<String, dynamic> _session({String eventId = _eventId}) => {
      'id': '123e4567-e89b-42d3-a456-426614174003',
      'clientEventId': eventId,
      'kind': 'memorization',
      'durationSeconds': 65,
      'occurredAt': '2026-10-15T05:00:00Z',
      'receivedAt': '2026-10-15T05:01:05Z',
    };

http.Response _jsonResponse(Object body, int statusCode) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test(
      'records a session using the protected child endpoint and stable event id',
      () async {
    late http.Request request;
    final repository = RestStudySessionsRepository(
      apiClient: _client(MockClient((incoming) async {
        request = incoming;
        return _jsonResponse(_session(eventId: 'event-1'), 201);
      })),
    );
    final draft = StudySessionDraft(
      clientEventId: _eventId,
      kind: StudySessionKind.memorization,
      durationSeconds: 65,
      occurredAt: DateTime.utc(2026, 10, 15, 5),
    );

    final saved = await repository.record(_childId, draft);

    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/children/$_childId/study-sessions');
    expect(request.headers['authorization'], 'Bearer test-id-token');
    expect(jsonDecode(request.body), {
      'clientEventId': _eventId,
      'kind': 'memorization',
      'durationSeconds': 65,
      'occurredAt': '2026-10-15T05:00:00.000Z',
    });
    expect(saved.durationSeconds, 65);
    expect(saved.kind, StudySessionKind.memorization);
  });

  test('loads recent session history from the child endpoint', () async {
    late http.Request request;
    final repository = RestStudySessionsRepository(
      apiClient: _client(MockClient((incoming) async {
        request = incoming;
        return _jsonResponse([_session()], 200);
      })),
    );

    final sessions = await repository.list(_childId);

    expect(request.method, 'GET');
    expect(request.url.path, '/api/v1/children/$_childId/study-sessions');
    expect(sessions.single.clientEventId, _eventId);
    expect(sessions.single.durationSeconds, 65);
    expect(sessions.single.occurredAt.isUtc, isTrue);
  });

  test('loads the full session summary from the protected summary endpoint',
      () async {
    late http.Request request;
    final repository = RestStudySessionsRepository(
      apiClient: _client(MockClient((incoming) async {
        request = incoming;
        return _jsonResponse({
          'sessionCount': 31,
          'totalDurationSeconds': 496,
        }, 200);
      })),
    );

    final summary = await repository.summary(_childId);

    expect(request.method, 'GET');
    expect(
        request.url.path, '/api/v1/children/$_childId/study-sessions/summary');
    expect(request.headers['authorization'], 'Bearer test-id-token');
    expect(summary.sessionCount, 31);
    expect(summary.totalDurationSeconds, 496);
  });

  test('generates a version 4 UUID event id', () {
    final draft = StudySessionDraft.create(
      kind: StudySessionKind.revision,
      durationSeconds: 12,
      occurredAt: DateTime.utc(2026, 10, 15),
      random: Random(17),
    );

    expect(
      draft.clientEventId,
      matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
    );
    expect(draft.occurredAt.isUtc, isTrue);
  });
}
