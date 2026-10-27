import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/children/data/children_providers.dart';
import 'features/children/presentation/child_profiles_screen.dart';
import 'features/study/data/study_sessions_providers.dart';
import 'features/study/presentation/study_session_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(childNameProvider);
    final colors = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList.list(children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('السَّلَامُ عَلَيْكُمْ',
                        style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(name == null ? 'مرحبًا ببطل القرآن' : 'أهلًا يا $name',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ])),
              CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.auto_awesome, color: colors.primary)),
            ]),
            const SizedBox(height: 24),
            _HomeProgressCard(childId: ref.watch(activeChildIdProvider)),
            const SizedBox(height: 25),
            Text('رحلتك اليوم', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ActionCard(
                icon: Icons.headphones_outlined,
                title: 'جلسة تعلّم',
                subtitle: 'سجّل مدة نشاطك؛ فهرس القرآن والتلاوة غير متاحين بعد',
                onTap: () => ref.read(selectedTabProvider.notifier).state =
                    AppTab.learn),
            _ActionCard(
                icon: Icons.replay_circle_filled_outlined,
                title: 'وقت المراجعة',
                subtitle: 'راجع ما تعلّمته سابقًا',
                onTap: () => ref.read(selectedTabProvider.notifier).state =
                    AppTab.learn),
            _ActionCard(
                icon: Icons.quiz_outlined,
                title: 'تحدّي قصير',
                subtitle: 'اختبر تذكّرك بطريقة ممتعة',
                onTap: () => ref.read(selectedTabProvider.notifier).state =
                    AppTab.tests),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _addChild(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(name == null
                  ? 'إعداد ملف الطفل (نموذج أولي)'
                  : 'تغيير اسم الطفل'),
            ),
            const SizedBox(height: 8),
            const Text(
                'يعرض الملخص آخر 30 جلسة محفوظة فقط؛ الأهداف والنقاط والسلاسل لم تُربط بعد.',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ),
      ],
    );
  }

  Future<void> _addChild(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملف الطفل'),
        content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'الاسم المعروض')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('متابعة')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty)
      ref.read(childNameProvider.notifier).state = value;
  }
}

class _HomeProgressCard extends ConsumerWidget {
  const _HomeProgressCard({required this.childId});

  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (childId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ملخص التعلّم',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('اختر ملف طفل من تبويب الأسرة لعرض جلساته المحفوظة.'),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => ref
                      .read(selectedTabProvider.notifier)
                      .state = AppTab.family,
                  child: const Text('اختيار ملف الطفل'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sessionsProvider = studySessionsForChildProvider(childId!);
    return ref.watch(sessionsProvider).when(
          loading: () => const Card(
            child: ListTile(
              leading: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('جار تحميل ملخص التعلّم'),
            ),
          ),
          error: (error, stackTrace) => Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ملخص التعلّم',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'تعذر تحميل الجلسات المحفوظة. تحقق من الاتصال ثم أعد المحاولة.'),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => ref.invalidate(sessionsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (sessions) {
            final totalDurationSeconds = sessions.fold<int>(
              0,
              (total, session) => total + session.durationSeconds,
            );
            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(Icons.insights,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'الجلسات المحفوظة (آخر 30 كحد أقصى)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.menu_book_outlined,
                        label: 'جلسة مسجلة',
                        value: _arabicDigits(sessions.length),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.timer_outlined,
                        label: 'وقت التعلّم',
                        value: _formatStudyDuration(totalDurationSeconds),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
  }
}

String _arabicDigits(int value) => value.toString().replaceAllMapped(
      RegExp(r'\d'),
      (match) => String.fromCharCode(0x0660 + int.parse(match.group(0)!)),
    );

String _formatStudyDuration(int totalSeconds) {
  final totalMinutes = totalSeconds ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  final seconds = totalSeconds % 60;
  final parts = <String>[];
  if (hours > 0) parts.add('${_arabicDigits(hours)} س');
  if (minutes > 0) parts.add('${_arabicDigits(minutes)} د');
  if (seconds > 0 || parts.isEmpty) parts.add('${_arabicDigits(seconds)} ث');
  return parts.join(' ');
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54))
                ])),
          ])));
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left)));
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context) => const StudySessionScreen();
}

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});
  @override
  Widget build(BuildContext context) => _FeaturePage(
      title: 'اختبر ما تعلّمت',
      icon: Icons.quiz,
      description: 'اختبارات قصيرة تشجّع التذكّر خطوة بخطوة.',
      notice:
          'ستُفعّل الاختبارات بعد ربط المحتوى المعتمد وتسجيل جلسات الحفظ؛ لا توجد أسئلة تجريبية بنص قرآني غير موثّق.',
      actions: const ['أكمل الآية', 'رتّب الآيات', 'اختيار من متعدد']);
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) => _FeaturePage(
      title: 'إنجازاتي',
      icon: Icons.emoji_events,
      description: 'كل خطوة صغيرة تستحق التقدير.',
      notice:
          'ستظهر النقاط والشارات بعد ربط الأنشطة بقواعد مكافآت موثوقة؛ رصيدك الحالي ٠ في النموذج الأولي.',
      actions: const ['نقاط التعلّم', 'الشارات', 'المكافآت العائلية']);
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) => const ChildProfilesScreen();
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage(
      {required this.title,
      required this.icon,
      required this.description,
      required this.notice,
      required this.actions});
  final String title;
  final IconData icon;
  final String description;
  final String notice;
  final List<String> actions;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 12),
        CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 30)),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(child: Text(notice))
                    ]))),
        const SizedBox(height: 16),
        for (final action in actions)
          Card(
              child: ListTile(
                  title: Text(action),
                  trailing: const Icon(Icons.lock_outline),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'ستتوفر هذه الميزة بعد اكتمال ربط الخدمات.'))))),
      ]);
}
