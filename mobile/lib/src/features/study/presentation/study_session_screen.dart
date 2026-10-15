import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../children/domain/child_profile.dart';
import '../../children/presentation/children_controller.dart';
import '../data/study_sessions_providers.dart';
import '../domain/study_session.dart';

class StudySessionScreen extends ConsumerStatefulWidget {
  const StudySessionScreen({super.key});

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  String? _selectedChildId;
  StudySessionKind _selectedKind = StudySessionKind.memorization;
  StudySessionKind? _runningKind;
  String? _runningChildId;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  StudySessionDraft? _pendingDraft;
  String? _pendingChildId;
  String? _saveError;
  bool _isSaving = false;

  bool get _isRunning => _startedAt != null && _pendingDraft == null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(childProfilesControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const SizedBox(height: 12),
        Text('جلسة تعلّم', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'سجّل مدة نشاطك ونوعه. لا يتضمن التطبيق حتى الآن نصًا قرآنيًا أو تلاوة معتمدة.',
        ),
        const SizedBox(height: 18),
        profiles.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _InlineError(
            message: 'تعذر تحميل ملفات الأسرة. تحقّق من تسجيل الدخول والاتصال.',
            onRetry: () => ref.invalidate(childProfilesControllerProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('أضف ملف طفل من تبويب الأسرة قبل تسجيل الجلسة.'),
                ),
              );
            }
            final childId = _effectiveChildId(items);
            final history = ref.watch(studySessionsForChildProvider(childId));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('child-$childId'),
                  initialValue: childId,
                  decoration: const InputDecoration(labelText: 'ملف الطفل'),
                  items: [
                    for (final child in items)
                      DropdownMenuItem(
                        value: child.id,
                        child: Text(child.name),
                      ),
                  ],
                  onChanged: _controlsLocked
                      ? null
                      : (value) => setState(() => _selectedChildId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StudySessionKind>(
                  key: ValueKey('kind-${_runningKind ?? _selectedKind}'),
                  initialValue: _isRunning ? _runningKind : _selectedKind,
                  decoration: const InputDecoration(labelText: 'نوع النشاط'),
                  items: [
                    for (final kind in StudySessionKind.values)
                      DropdownMenuItem(value: kind, child: Text(kind.label)),
                  ],
                  onChanged: _controlsLocked
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedKind = value);
                          }
                        },
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Semantics(
                          liveRegion: true,
                          label: 'المدة ${_formatDuration(_elapsed)}',
                          child: Text(
                            _formatDuration(_elapsed),
                            key: const Key('study-session-elapsed'),
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_pendingDraft == null)
                          FilledButton.icon(
                            key: const Key('study-session-action'),
                            onPressed: _isSaving
                                ? null
                                : _isRunning
                                    ? (_elapsed.inSeconds >= 1
                                        ? _finishSession
                                        : null)
                                    : () => _startSession(childId),
                            icon: Icon(
                                _isRunning ? Icons.stop : Icons.play_arrow),
                            label: Text(_isRunning
                                ? 'إنهاء وتسجيل الجلسة'
                                : 'بدء الجلسة'),
                          )
                        else
                          FilledButton.icon(
                            key: const Key('study-session-retry'),
                            onPressed: _isSaving ? null : _retrySave,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_isSaving
                                ? 'جارٍ الحفظ...'
                                : 'إعادة محاولة حفظ الجلسة'),
                          ),
                        if (_saveError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _saveError!,
                            key: const Key('study-session-save-error'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text('الجلسات الأخيرة',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                history.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => _InlineError(
                    message: 'تعذر تحميل السجل. أعد المحاولة.',
                    onRetry: () =>
                        ref.invalidate(studySessionsForChildProvider(childId)),
                  ),
                  data: (sessions) => sessions.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('لا توجد جلسات مسجلة لهذا الطفل بعد.'),
                          ),
                        )
                      : Column(
                          children: [
                            for (final session in sessions)
                              Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.menu_book_outlined),
                                  ),
                                  title: Text(
                                      '${session.kind.label} · ${_formatDuration(Duration(seconds: session.durationSeconds))}'),
                                  subtitle: Text(
                                      'بدأت ${_formatLocalTime(session.occurredAt)}'),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  bool get _controlsLocked => _isRunning || _pendingDraft != null || _isSaving;

  String _effectiveChildId(List<ChildProfile> profiles) {
    if (profiles.any((profile) => profile.id == _selectedChildId)) {
      return _selectedChildId!;
    }
    return profiles.first.id;
  }

  void _startSession(String childId) {
    final startedAt = ref.read(studySessionClockProvider)().toUtc();
    setState(() {
      _selectedChildId = childId;
      _runningChildId = childId;
      _runningKind = _selectedKind;
      _startedAt = startedAt;
      _elapsed = Duration.zero;
      _saveError = null;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final began = _startedAt;
      if (!mounted || began == null) return;
      setState(() => _elapsed =
          ref.read(studySessionClockProvider)().toUtc().difference(began));
    });
  }

  void _finishSession() {
    final began = _startedAt;
    final kind = _runningKind;
    final childId = _runningChildId;
    if (began == null || kind == null || childId == null) return;
    final seconds = ref
        .read(studySessionClockProvider)()
        .toUtc()
        .difference(began)
        .inSeconds;
    if (seconds < 1) return;
    _ticker?.cancel();
    setState(() {
      _pendingDraft = StudySessionDraft.create(
        kind: kind,
        durationSeconds: seconds.clamp(1, 28800).toInt(),
        occurredAt: began,
      );
      _pendingChildId = childId;
      _saveError = null;
    });
    _retrySave();
  }

  Future<void> _retrySave() async {
    final draft = _pendingDraft;
    final childId = _pendingChildId;
    if (draft == null || childId == null || _isSaving) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await ref.read(studySessionsRepositoryProvider).record(childId, draft);
      if (!mounted) return;
      ref.invalidate(studySessionsForChildProvider(childId));
      setState(() {
        _pendingDraft = null;
        _pendingChildId = null;
        _startedAt = null;
        _runningChildId = null;
        _runningKind = null;
        _elapsed = Duration.zero;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الجلسة بنجاح.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError =
            'تعذر حفظ الجلسة. ستظل بياناتها ومعرّفها كما هما؛ أعد المحاولة.';
      });
    }
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:$minutes:$seconds'
      : '$minutes:$seconds';
}

String _formatLocalTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
