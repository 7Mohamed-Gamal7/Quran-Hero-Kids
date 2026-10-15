import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hero_kids/src/features/children/domain/child_profile.dart';
import 'package:quran_hero_kids/src/features/children/presentation/children_controller.dart';
import 'package:quran_hero_kids/src/features/study/data/study_sessions_providers.dart';
import 'package:quran_hero_kids/src/features/study/data/study_sessions_repository.dart';
import 'package:quran_hero_kids/src/features/study/domain/study_session.dart';
import 'package:quran_hero_kids/src/features/study/presentation/study_session_screen.dart';

class _TestChildProfilesController extends ChildProfilesController {
  @override
  Future<List<ChildProfile>> build() async => const [
        ChildProfile(
            id: '123e4567-e89b-42d3-a456-426614174002',
            name: 'ليان',
            ageBand: '8-10'),
      ];
}

class _FakeStudySessionsRepository implements StudySessionsRepository {
  final attempts = <StudySessionDraft>[];
  final saved = <StudySessionRecord>[];
  bool failFirstRecord = false;

  @override
  Future<List<StudySessionRecord>> list(String childId) async =>
      List.unmodifiable(saved.reversed);

  @override
  Future<StudySessionRecord> record(
      String childId, StudySessionDraft draft) async {
    attempts.add(draft);
    if (failFirstRecord && attempts.length == 1) {
      throw StateError('temporary network failure');
    }
    final record = StudySessionRecord(
      id: 'session-${saved.length + 1}',
      clientEventId: draft.clientEventId,
      kind: draft.kind,
      durationSeconds: draft.durationSeconds,
      occurredAt: draft.occurredAt,
      receivedAt: DateTime.utc(2026, 10, 15, 5, 1),
    );
    saved.insert(0, record);
    return record;
  }
}

Widget _app(
        _FakeStudySessionsRepository repository, DateTime Function() clock) =>
    ProviderScope(
      overrides: [
        childProfilesControllerProvider
            .overrideWith(_TestChildProfilesController.new),
        studySessionsRepositoryProvider.overrideWithValue(repository),
        studySessionClockProvider.overrideWithValue(clock),
      ],
      child: const MaterialApp(
        home: Scaffold(body: StudySessionScreen()),
      ),
    );

void main() {
  testWidgets('records a timed session and refreshes the recent history',
      (tester) async {
    var now = DateTime.utc(2026, 10, 15, 5);
    final repository = _FakeStudySessionsRepository();
    await tester.pumpWidget(_app(repository, () => now));
    await tester.pumpAndSettle();

    expect(find.text('ملف الطفل'), findsOneWidget);
    expect(find.text('بدء الجلسة'), findsOneWidget);
    expect(find.textContaining('لا يتضمن التطبيق حتى الآن'), findsOneWidget);

    await tester.tap(find.text('بدء الجلسة'));
    await tester.pump();
    now = now.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('00:03'), findsOneWidget);
    await tester.tap(find.text('إنهاء وتسجيل الجلسة'));
    await tester.pumpAndSettle();

    expect(repository.attempts, hasLength(1));
    expect(repository.attempts.single.durationSeconds, 3);
    expect(repository.attempts.single.kind, StudySessionKind.memorization);
    expect(repository.saved.single.clientEventId,
        repository.attempts.single.clientEventId);
    expect(find.text('تم تسجيل الجلسة بنجاح.'), findsOneWidget);
    expect(find.text('حفظ · 00:03'), findsOneWidget);
  });

  testWidgets('retry keeps the exact event id and original payload',
      (tester) async {
    var now = DateTime.utc(2026, 10, 15, 5);
    final repository = _FakeStudySessionsRepository()..failFirstRecord = true;
    await tester.pumpWidget(_app(repository, () => now));
    await tester.pumpAndSettle();

    await tester.tap(find.text('بدء الجلسة'));
    await tester.pump();
    now = now.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('إنهاء وتسجيل الجلسة'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('study-session-save-error')), findsOneWidget);
    expect(repository.attempts, hasLength(1));
    final firstAttempt = repository.attempts.single;

    await tester.tap(find.text('إعادة محاولة حفظ الجلسة'));
    await tester.pumpAndSettle();

    expect(repository.attempts, hasLength(2));
    expect(repository.attempts[1].clientEventId, firstAttempt.clientEventId);
    expect(repository.attempts[1].kind, firstAttempt.kind);
    expect(
        repository.attempts[1].durationSeconds, firstAttempt.durationSeconds);
    expect(repository.attempts[1].occurredAt, firstAttempt.occurredAt);
    expect(find.text('تم تسجيل الجلسة بنجاح.'), findsOneWidget);
  });
}
