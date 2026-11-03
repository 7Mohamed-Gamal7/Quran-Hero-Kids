import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_hero_kids/src/features/children/data/children_providers.dart';
import 'package:quran_hero_kids/src/features/children/domain/child_profile.dart';
import 'package:quran_hero_kids/src/features/children/presentation/children_controller.dart';

class _FailRefreshAfterMutationRepository implements ChildProfilesRepository {
  _FailRefreshAfterMutationRepository([List<ChildProfile> initial = const []])
      : children = [...initial];

  var listCalls = 0;
  final List<ChildProfile> children;

  @override
  Future<List<ChildProfile>> list() async {
    listCalls++;
    if (listCalls == 2) throw StateError('refresh failed');
    return List.unmodifiable(children);
  }

  @override
  Future<ChildProfile> create(ChildProfileDraft draft) async {
    final created = ChildProfile(id: 'created', name: draft.name);
    children.add(created);
    return created;
  }

  @override
  Future<ChildProfile> getById(String id) async =>
      children.singleWhere((child) => child.id == id);

  @override
  Future<ChildProfile> update(String id, ChildProfileDraft draft) async {
    final updated = ChildProfile(id: id, name: draft.name);
    children[children.indexWhere((child) => child.id == id)] = updated;
    return updated;
  }

  @override
  Future<void> archive(String id) async {
    children.removeWhere((child) => child.id == id);
  }
}

ProviderContainer _containerFor(
    _FailRefreshAfterMutationRepository repository) {
  final container = ProviderContainer(overrides: [
    childProfilesRepositoryProvider.overrideWithValue(repository),
  ]);
  return container;
}

void main() {
  test('keeps a successful create successful when refreshing the list fails',
      () async {
    final repository = _FailRefreshAfterMutationRepository();
    final container = _containerFor(repository);
    addTearDown(container.dispose);

    await container.read(childProfilesControllerProvider.future);
    final succeeded = await container
        .read(childProfilesControllerProvider.notifier)
        .create(const ChildProfileDraft(name: 'ليان'));
    final result = container.read(childProfilesControllerProvider);

    expect(succeeded, isTrue);
    expect(result.hasError, isFalse);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.single.name, 'ليان');
    expect(repository.children, hasLength(1));
  });

  test('keeps an edited profile after the list refresh fails', () async {
    const original = ChildProfile(id: 'child-1', name: 'قبل');
    final repository = _FailRefreshAfterMutationRepository([original]);
    final container = _containerFor(repository);
    addTearDown(container.dispose);
    await container.read(childProfilesControllerProvider.future);

    final succeeded = await container
        .read(childProfilesControllerProvider.notifier)
        .edit('child-1', const ChildProfileDraft(name: 'بعد'));
    final result = container.read(childProfilesControllerProvider);

    expect(succeeded, isTrue);
    expect(result.valueOrNull!.single.name, 'بعد');
  });

  test('removes an archived profile locally when the list refresh fails',
      () async {
    const original = ChildProfile(id: 'child-1', name: 'ليان');
    final repository = _FailRefreshAfterMutationRepository([original]);
    final container = _containerFor(repository);
    addTearDown(container.dispose);
    await container.read(childProfilesControllerProvider.future);

    final succeeded = await container
        .read(childProfilesControllerProvider.notifier)
        .archive('child-1');
    final result = container.read(childProfilesControllerProvider);

    expect(succeeded, isTrue);
    expect(result.valueOrNull, isEmpty);
    expect(repository.children, isEmpty);
  });
}
