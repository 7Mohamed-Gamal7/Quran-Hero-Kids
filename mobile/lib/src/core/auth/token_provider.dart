/// Supplies a Firebase ID token for authenticated API calls.
///
/// The Firebase implementation belongs at this boundary once the app has a
/// configured Firebase project. No fake token or anonymous fallback is used.
abstract interface class TokenProvider {
  Future<String?> getIdToken();
}

/// Explicitly represents an app build that has not configured authentication.
class MissingTokenProvider implements TokenProvider {
  const MissingTokenProvider();

  @override
  Future<String?> getIdToken() async => null;
}
