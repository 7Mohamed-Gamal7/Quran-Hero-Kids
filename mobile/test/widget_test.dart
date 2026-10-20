import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hero_kids/src/app.dart';

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

    expect(find.text('هدف اليوم'), findsOneWidget);
    expect(find.text('التعلّم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders Arabic home dashboard and accessible navigation',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuranHeroApp()));

    expect(find.text('مرحبًا ببطل القرآن'), findsOneWidget);
    expect(find.text('هدف اليوم'), findsOneWidget);
    expect(find.text('التعلّم'), findsOneWidget);
    expect(find.text('الأسرة'), findsOneWidget);
    expect(find.text('جلسة تعلّم'), findsOneWidget);
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
}
