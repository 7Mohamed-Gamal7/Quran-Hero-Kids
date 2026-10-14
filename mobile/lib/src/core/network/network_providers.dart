import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/token_provider.dart';
import 'api_client.dart';
import 'api_config.dart';

final apiConfigProvider =
    Provider<ApiConfig>((ref) => ApiConfig.fromEnvironment());

/// Replace this provider with a Firebase-backed TokenProvider after project setup.
final tokenProviderProvider = Provider<TokenProvider>(
  (ref) => const MissingTokenProvider(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  return ApiClient(
    config: ref.watch(apiConfigProvider),
    tokenProvider: ref.watch(tokenProviderProvider),
    httpClient: httpClient,
  );
});
