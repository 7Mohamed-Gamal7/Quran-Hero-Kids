import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import 'children_repository.dart';

export 'children_repository.dart';

final childProfilesRepositoryProvider =
    Provider<ChildProfilesRepository>((ref) {
  return RestChildProfilesRepository(apiClient: ref.watch(apiClientProvider));
});

final activeChildIdProvider = StateProvider<String?>((ref) => null);
