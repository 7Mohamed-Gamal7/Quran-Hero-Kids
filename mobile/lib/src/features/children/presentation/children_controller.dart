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

  Future<bool> create(ChildProfileDraft draft) =>
      _mutate(() => _repository.create(draft));

  Future<bool> edit(String id, ChildProfileDraft draft) =>
      _mutate(() => _repository.update(id, draft));

  Future<bool> archive(String id) => _mutate(() => _repository.archive(id));

  Future<bool> _mutate(Future<dynamic> Function() operation) async {
    final previous = state.valueOrNull ?? const <ChildProfile>[];
    state = AsyncLoading<List<ChildProfile>>().copyWithPrevious(state);
    try {
      await operation();
      state = AsyncData(await _repository.list());
      return true;
    } catch (error, stackTrace) {
      state = AsyncError<List<ChildProfile>>(error, stackTrace)
          .copyWithPrevious(AsyncData(previous));
      return false;
    }
  }
}
