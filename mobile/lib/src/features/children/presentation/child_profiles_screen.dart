import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/child_profile.dart';
import 'children_controller.dart';

class ChildProfilesScreen extends ConsumerWidget {
  const ChildProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(childProfilesControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.family_restroom,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('لوحة الأسرة',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('أضف ملف طفل لمتابعة أهدافه وتقدمه.'),
        const SizedBox(height: 20),
        state.when(
          loading: () => const _LoadingView(),
          error: (error, _) => _ErrorView(
            error: error,
            onRetry: () =>
                ref.read(childProfilesControllerProvider.notifier).refresh(),
          ),
          data: (profiles) => _ProfilesView(profiles: profiles),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Semantics(
                label: 'جار تحميل ملفات الأطفال',
                liveRegion: true,
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 12),
              Text('جار تحميل ملفات الأطفال...'),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = _friendlyError(error);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 10),
            Text(message, key: const Key('children-error')),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilesView extends ConsumerWidget {
  const _ProfilesView({required this.profiles});

  final List<ChildProfile> profiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _openEditor(context, ref),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('إضافة ملف طفل'),
        ),
        const SizedBox(height: 16),
        if (profiles.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 36),
                  SizedBox(height: 10),
                  Text('لا توجد ملفات أطفال بعد.'),
                  SizedBox(height: 4),
                  Text('أضف أول ملف للبدء.', textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          ...profiles.map(
            (profile) => _ProfileCard(profile: profile),
          ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      [ChildProfile? profile]) async {
    final draft = await showDialog<ChildProfileDraft>(
      context: context,
      builder: (context) => _ChildProfileDialog(profile: profile),
    );
    if (draft == null || !context.mounted) return;
    final controller = ref.read(childProfilesControllerProvider.notifier);
    final success = profile == null
        ? await controller.create(draft)
        : await controller.edit(profile.id, draft);
    if (!context.mounted || success) return;
    _showMutationError(
        context, ref.read(childProfilesControllerProvider).error);
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Text(
                profile.name.isEmpty ? '?' : profile.name.characters.first),
          ),
          title: Text(profile.name),
          subtitle: Text(profile.ageBand == null
              ? 'الفئة العمرية غير محددة'
              : 'الفئة العمرية: ${profile.ageBand} سنة'),
          isThreeLine: false,
          trailing: PopupMenuButton<String>(
            tooltip: 'إجراءات ${profile.name}',
            onSelected: (value) async {
              if (value == 'edit') {
                await _edit(context, ref);
              } else if (value == 'archive') {
                await _archive(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(value: 'archive', child: Text('أرشفة')),
            ],
          ),
        ),
      );

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final draft = await showDialog<ChildProfileDraft>(
      context: context,
      builder: (context) => _ChildProfileDialog(profile: profile),
    );
    if (draft == null || !context.mounted) return;
    final success = await ref
        .read(childProfilesControllerProvider.notifier)
        .edit(profile.id, draft);
    if (!context.mounted || success) return;
    _showMutationError(
        context, ref.read(childProfilesControllerProvider).error);
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أرشفة ملف الطفل؟'),
        content: Text('لن يظهر ${profile.name} في القائمة النشطة بعد الأرشفة.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('أرشفة')),
        ],
      ),
    );
    if (shouldArchive != true || !context.mounted) return;
    final success = await ref
        .read(childProfilesControllerProvider.notifier)
        .archive(profile.id);
    if (!context.mounted || success) return;
    _showMutationError(
        context, ref.read(childProfilesControllerProvider).error);
  }
}

class _ChildProfileDialog extends StatefulWidget {
  const _ChildProfileDialog({this.profile});

  final ChildProfile? profile;

  @override
  State<_ChildProfileDialog> createState() => _ChildProfileDialogState();
}

class _ChildProfileDialogState extends State<_ChildProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _ageBand;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name);
    _ageBand = widget.profile?.ageBand;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.profile == null ? 'إضافة ملف طفل' : 'تعديل ملف الطفل'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'اسم الطفل'),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return 'أدخل اسم الطفل';
                  if (name.length > 100) return 'الاسم طويل جدًا';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _ageBand,
                decoration:
                    const InputDecoration(labelText: 'الفئة العمرية (اختياري)'),
                items: const [
                  DropdownMenuItem(value: '5-7', child: Text('5–7 سنوات')),
                  DropdownMenuItem(value: '8-10', child: Text('8–10 سنوات')),
                  DropdownMenuItem(value: '11-13', child: Text('11–13 سنة')),
                  DropdownMenuItem(value: '14+', child: Text('14 سنة فأكثر')),
                ],
                onChanged: (value) => setState(() => _ageBand = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(
                context,
                ChildProfileDraft(
                    name: _nameController.text, ageBand: _ageBand),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      );
}

String _friendlyError(Object error) {
  if (error is ApiException) return error.message;
  return 'حدث خطأ غير متوقع. تحقّق من الاتصال وحاول مرة أخرى.';
}

void _showMutationError(BuildContext context, Object? error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_friendlyError(error ?? 'unknown'))),
  );
}
