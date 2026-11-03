import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/children_providers.dart';
import '../domain/child_profile.dart';

final childProfilesControllerProvider =
    AsyncNotifierProvider<ChildProfilesController, List<ChildProfile>>(
  ChildProfilesController.new,
);

class ChildProfilesController extends AsyncNotifier<List<ChildProfile>> {
  ChildProfilesRepository get _repository =>
      ref.read(childProfilesRepositoryProvider);

  @override
  Future<List<ChildProfile>> build() => _repository.list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.list);
  }

  Future<bool> create(ChildProfileDraft draft) async {
    return _mutate(
      () => _repository.create(draft),
      onRefreshFailure: (profiles, result) =>
          result is ChildProfile ? [...profiles, result] : profiles,
    );
  }

  Future<bool> edit(String id, ChildProfileDraft draft) async {
    return _mutate(
      () => _repository.update(id, draft),
      onRefreshFailure: (profiles, result) => result is! ChildProfile
          ? profiles
          : profiles
              .map((profile) => profile.id == id ? result : profile)
              .toList(growable: false),
    );
  }

  Future<bool> archive(String id) => _mutate(
        () => _repository.archive(id),
        onRefreshFailure: (profiles, _) =>
            profiles.where((profile) => profile.id != id).toList(),
      );

  Future<bool> _mutate(
    Future<dynamic> Function() operation, {
    required List<ChildProfile> Function(
      List<ChildProfile> profiles,
      dynamic result,
    ) onRefreshFailure,
  }) async {
    final previous = state.valueOrNull ?? const <ChildProfile>[];
    state = AsyncLoading<List<ChildProfile>>().copyWithPrevious(state);
    dynamic result;
    try {
      result = await operation();
    } catch (error, stackTrace) {
      state = AsyncError<List<ChildProfile>>(error, stackTrace)
          .copyWithPrevious(AsyncData(previous));
      return false;
    }

    try {
      state = AsyncData(await _repository.list());
    } catch (_) {
      // The write succeeded; keep its confirmed result visible instead of
      // reporting a failed mutation and inviting a duplicate retry.
      state = AsyncData(onRefreshFailure(previous, result));
    }
    return true;
  }
}
