class ApiConfig {
  const ApiConfig({required this.baseUrl});

  factory ApiConfig.fromEnvironment() =>
      const ApiConfig(baseUrl: String.fromEnvironment('API_BASE_URL'));

  final String baseUrl;

  bool get isConfigured {
    final value = baseUrl.trim();
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Uri get uri {
    if (!isConfigured) {
      throw const FormatException('API_BASE_URL is missing or invalid.');
    }
    return Uri.parse(baseUrl.trim());
  }
}
