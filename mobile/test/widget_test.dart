import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hero_kids/src/app.dart';

void main() {
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
