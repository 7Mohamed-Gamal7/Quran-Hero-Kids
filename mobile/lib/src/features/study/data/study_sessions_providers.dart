import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/study_session.dart';
import 'study_sessions_repository.dart';

final studySessionsRepositoryProvider = Provider<StudySessionsRepository>(
  (ref) => RestStudySessionsRepository(apiClient: ref.watch(apiClientProvider)),
);

final studySessionClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final studySessionsForChildProvider =
    FutureProvider.family<List<StudySessionRecord>, String>(
  (ref, childId) => ref.watch(studySessionsRepositoryProvider).list(childId),
);

final studySessionSummaryForChildProvider =
    FutureProvider.family<StudySessionSummary, String>(
  (ref, childId) => ref.watch(studySessionsRepositoryProvider).summary(childId),
);
