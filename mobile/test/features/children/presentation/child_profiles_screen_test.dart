import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hero_kids/src/core/network/api_exception.dart';
import 'package:quran_hero_kids/src/features/children/data/children_providers.dart';
import 'package:quran_hero_kids/src/features/children/domain/child_profile.dart';
import 'package:quran_hero_kids/src/features/children/presentation/child_profiles_screen.dart';

class _FakeChildrenRepository implements ChildProfilesRepository {
  _FakeChildrenRepository(this.children, {this.failure});

  List<ChildProfile> children;
  final Object? failure;

  @override
  Future<List<ChildProfile>> list() async {
    if (failure != null) throw failure!;
    return children;
  }

  @override
  Future<ChildProfile> getById(String id) async => children.first;

  @override
  Future<ChildProfile> create(ChildProfileDraft draft) async {
    final child =
        ChildProfile(id: 'new', name: draft.name, ageBand: draft.ageBand);
    children = [...children, child];
    return child;
  }

  @override
  Future<ChildProfile> update(String id, ChildProfileDraft draft) async =>
      ChildProfile(id: id, name: draft.name, ageBand: draft.ageBand);

  @override
  Future<void> archive(String id) async {
    children = children.where((child) => child.id != id).toList();
  }
}

Widget _testApp(_FakeChildrenRepository repository) => ProviderScope(
      overrides: [
        childProfilesRepositoryProvider.overrideWithValue(repository)
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: ChildProfilesScreen()),
        ),
      ),
    );

void main() {
  testWidgets('shows an empty state and add action', (tester) async {
    await tester.pumpWidget(_testApp(_FakeChildrenRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد ملفات أطفال بعد.'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('إضافة ملف طفل'),
        matching: find.bySubtype<FilledButton>(),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a clear configuration error and retry action',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        _FakeChildrenRepository(
          [],
          failure: const ApiException(
            type: ApiFailureType.configuration,
            message: 'عنوان API غير مهيأ. شغّل التطبيق مع API_BASE_URL.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('عنوان API غير مهيأ. شغّل التطبيق مع API_BASE_URL.'),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('renders child profiles and validates the add form',
      (tester) async {
    final repository = _FakeChildrenRepository([
      const ChildProfile(id: '1', name: 'ليان'),
    ]);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('ليان'), findsOneWidget);
    await tester.tap(find.text('إضافة ملف طفل'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('حفظ'));
    await tester.pump();
    expect(find.text('أدخل اسم الطفل'), findsOneWidget);
  });

  testWidgets('archiving the active child selects a remaining profile',
      (tester) async {
    final repository = _FakeChildrenRepository(const [
      ChildProfile(id: '1', name: 'ليان'),
      ChildProfile(id: '2', name: 'عمر'),
    ]);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('select-active-child-2')));
    await tester.pumpAndSettle();
    expect(find.text('الطفل النشط'), findsOneWidget);

    await tester.tap(find.byTooltip('إجراءات عمر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أرشفة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أرشفة'));
    await tester.pumpAndSettle();

    expect(find.text('عمر'), findsNothing);
    expect(find.text('ليان'), findsOneWidget);
    expect(find.text('الطفل النشط'), findsOneWidget);
    expect(find.byKey(const Key('select-active-child-1')), findsNothing);
  });

  testWidgets('archiving the only active child clears active selection',
      (tester) async {
    final repository = _FakeChildrenRepository(const [
      ChildProfile(id: '1', name: 'ليان'),
    ]);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('select-active-child-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إجراءات ليان'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أرشفة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أرشفة'));
    await tester.pumpAndSettle();

    expect(find.text('ليان'), findsNothing);
    expect(find.text('لا توجد ملفات أطفال بعد.'), findsOneWidget);
    expect(find.text('الطفل النشط'), findsNothing);
  });

  testWidgets('selects an active child and identifies it accessibly',
      (tester) async {
    final repository = _FakeChildrenRepository(const [
      ChildProfile(id: '1', name: 'ليان'),
      ChildProfile(id: '2', name: 'عمر'),
    ]);
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('select-active-child-2')));
    await tester.pumpAndSettle();

    expect(find.text('الطفل النشط'), findsOneWidget);
    expect(find.byKey(const Key('select-active-child-2')), findsNothing);
    expect(find.byKey(const Key('select-active-child-1')), findsOneWidget);
  });
}
