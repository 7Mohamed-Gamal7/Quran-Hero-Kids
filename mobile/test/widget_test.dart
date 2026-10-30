import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hero_kids/src/app.dart';
import 'package:quran_hero_kids/src/features/children/data/children_providers.dart';
import 'package:quran_hero_kids/src/features/children/domain/child_profile.dart';
import 'package:quran_hero_kids/src/features/study/data/study_sessions_providers.dart';
import 'package:quran_hero_kids/src/features/study/data/study_sessions_repository.dart';
import 'package:quran_hero_kids/src/features/study/domain/study_session.dart';

void main() {
  testWidgets('home and navigation fit a narrow screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(const ProviderScope(child: QuranHeroApp()));
    await tester.pumpAndSettle();

    expect(find.text('ملخص التعلّم'), findsOneWidget);
    expect(find.text('التعلّم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child profile dialog fits a narrow screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childProfilesRepositoryProvider
              .overrideWithValue(_EmptyChildProfilesRepository()),
        ],
        child: const QuranHeroApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأسرة'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('إضافة ملف طفل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة ملف طفل'));
    await tester.pumpAndSettle();

    expect(find.text('اسم الطفل'), findsOneWidget);
    expect(find.text('الفئة العمرية'), findsOneWidget);
    expect(find.text('اختياري'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation destinations expose accessible button semantics',
      (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const ProviderScope(child: QuranHeroApp()));

      final home = tester
          .getSemantics(find.bySemanticsLabel('الرئيسية'))
          .getSemanticsData();
      expect(home.label, 'الرئيسية');
      expect(home.flagsCollection.isButton, isTrue);
      expect(home.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(home.hasAction(ui.SemanticsAction.tap), isTrue);

      final learn = tester
          .getSemantics(find.bySemanticsLabel('التعلّم'))
          .getSemanticsData();
      expect(learn.label, 'التعلّم');
      expect(learn.flagsCollection.isButton, isTrue);
      expect(learn.hasAction(ui.SemanticsAction.tap), isTrue);
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('renders Arabic home dashboard and accessible navigation',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuranHeroApp()));

    expect(find.text('مرحبًا ببطل القرآن'), findsOneWidget);
    expect(find.text('إعداد ملف الطفل (نموذج أولي)'), findsNothing);
    expect(find.text('ملخص التعلّم'), findsOneWidget);
    expect(
      find.text('اختر ملف طفل من تبويب الأسرة لعرض جلساته المحفوظة.'),
      findsOneWidget,
    );
    expect(find.text('التعلّم'), findsOneWidget);
    expect(find.text('الأسرة'), findsOneWidget);
    expect(find.text('جلسة تعلّم'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('إدارة ملفات الأطفال'), 300);
    expect(find.text('إدارة ملفات الأطفال'), findsOneWidget);
    expect(
      find.text('سجّل مدة نشاطك؛ فهرس القرآن والتلاوة غير متاحين بعد'),
      findsOneWidget,
    );
    expect(find.text('اختر سورة وابدأ جلسة تعلّم'), findsNothing);

    await tester.tap(find.text('الأسرة'));
    await tester.pumpAndSettle();

    expect(find.text('لوحة الأسرة'), findsOneWidget);
    expect(find.text('أضف ملف طفل لمتابعة أهدافه وتقدمه.'), findsOneWidget);
  });

  testWidgets('home uses active profile name and all-session totals',
      (tester) async {
    final sessionsRepository = _FakeStudySessionsRepository([
      _session('session-1', StudySessionKind.memorization, 125),
      _session('session-2', StudySessionKind.revision, 35),
    ],
        summaryOverride: const StudySessionSummary(
          sessionCount: 31,
          totalDurationSeconds: 496,
        ));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childProfilesRepositoryProvider
              .overrideWithValue(_SingleChildProfilesRepository()),
          studySessionsRepositoryProvider.overrideWithValue(sessionsRepository),
        ],
        child: const QuranHeroApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الأسرة'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-active-child-child-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();

    expect(find.text('أهلًا يا ليان'), findsOneWidget);
    expect(sessionsRepository.summarizedChildIds, ['child-1']);
    expect(find.text('٣١'), findsOneWidget);
    expect(find.text('٨ د ١٦ ث'), findsOneWidget);
    expect(find.text('الجلسات المحفوظة (كامل السجل)'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('إدارة ملفات الأطفال'), 300);
    await tester.tap(find.text('إدارة ملفات الأطفال'));
    await tester.pumpAndSettle();
    expect(find.text('لوحة الأسرة'), findsOneWidget);
  });
}

StudySessionRecord _session(
  String id,
  StudySessionKind kind,
  int durationSeconds,
) =>
    StudySessionRecord(
      id: id,
      clientEventId: 'event-$id',
      kind: kind,
      durationSeconds: durationSeconds,
      occurredAt: DateTime.utc(2026, 10, 26, 8),
      receivedAt: DateTime.utc(2026, 10, 26, 8),
    );

class _EmptyChildProfilesRepository implements ChildProfilesRepository {
  @override
  Future<List<ChildProfile>> list() async => const [];

  @override
  Future<ChildProfile> create(ChildProfileDraft draft) async => ChildProfile(
        id: 'child-1',
        name: draft.name,
        ageBand: draft.ageBand,
      );

  @override
  Future<ChildProfile> getById(String id) => throw UnimplementedError();

  @override
  Future<ChildProfile> update(String id, ChildProfileDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> archive(String id) async {}
}

class _SingleChildProfilesRepository implements ChildProfilesRepository {
  static const child = ChildProfile(id: 'child-1', name: 'ليان');

  @override
  Future<List<ChildProfile>> list() async => const [child];

  @override
  Future<ChildProfile> create(ChildProfileDraft draft) async => child;

  @override
  Future<ChildProfile> getById(String id) async => child;

  @override
  Future<ChildProfile> update(String id, ChildProfileDraft draft) async =>
      child;

  @override
  Future<void> archive(String id) async {}
}

class _FakeStudySessionsRepository implements StudySessionsRepository {
  _FakeStudySessionsRepository(this.sessions, {this.summaryOverride});

  final List<StudySessionRecord> sessions;
  final StudySessionSummary? summaryOverride;
  final listedChildIds = <String>[];
  final summarizedChildIds = <String>[];

  @override
  Future<List<StudySessionRecord>> list(String childId) async {
    listedChildIds.add(childId);
    return sessions;
  }

  @override
  Future<StudySessionSummary> summary(String childId) async {
    summarizedChildIds.add(childId);
    return summaryOverride ??
        StudySessionSummary(
          sessionCount: sessions.length,
          totalDurationSeconds: sessions.fold<int>(
            0,
            (total, session) => total + session.durationSeconds,
          ),
        );
  }

  @override
  Future<StudySessionRecord> record(
    String childId,
    StudySessionDraft draft,
  ) async =>
      throw UnimplementedError();
}
