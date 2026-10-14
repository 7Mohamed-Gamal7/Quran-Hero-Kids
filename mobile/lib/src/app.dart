import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens.dart';

enum AppTab { home, learn, tests, achievements, family }

final selectedTabProvider = StateProvider<AppTab>((ref) => AppTab.home);
final childNameProvider = StateProvider<String?>((ref) => null);

class QuranHeroApp extends StatelessWidget {
  const QuranHeroApp({super.key});

  static const _seed = Color(0xFF146B59);

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF8F8F3),
    );
    return MaterialApp(
      title: 'بطل القرآن الصغير',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF8F8F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F8F3),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE9ECE5)),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w800, height: 1.25),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(height: 1.55),
          bodyMedium: TextStyle(height: 1.5),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AppShell(),
      ),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    LearnScreen(),
    TestsScreen(),
    AchievementsScreen(),
    FamilyScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final index = AppTab.values.indexOf(selected);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: _pages),
      ),
      bottomNavigationBar: _AppNavigationBar(
          selectedIndex: index,
          onSelected: (tab) {
            ref.read(selectedTabProvider.notifier).state = tab;
          }),
    );
  }
}

class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar(
      {required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<AppTab> onSelected;

  static const _items = <(AppTab, String, IconData, IconData)>[
    (AppTab.home, 'الرئيسية', Icons.home_outlined, Icons.home),
    (AppTab.learn, 'التعلّم', Icons.menu_book_outlined, Icons.menu_book),
    (AppTab.tests, 'اختبرني', Icons.quiz_outlined, Icons.quiz),
    (
      AppTab.achievements,
      'إنجازاتي',
      Icons.emoji_events_outlined,
      Icons.emoji_events
    ),
    (
      AppTab.family,
      'الأسرة',
      Icons.family_restroom_outlined,
      Icons.family_restroom
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                  child: _NavigationItem(
                item: _items[i],
                selected: selectedIndex == i,
                onTap: () => onSelected(_items[i].$1),
              )),
          ]),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem(
      {required this.item, required this.selected, required this.onTap});

  final (AppTab, String, IconData, IconData) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? Theme.of(context).colorScheme.primary : Colors.black54;
    return Semantics(
      button: true,
      selected: selected,
      label: item.$2,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(selected ? item.$4 : item.$3, color: color, size: 22),
              const SizedBox(height: 3),
              Text(item.$2,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}
