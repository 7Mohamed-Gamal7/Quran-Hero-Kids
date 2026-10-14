import '../../../core/network/api_client.dart';
import '../domain/child_profile.dart';

abstract interface class ChildProfilesRepository {
  Future<List<ChildProfile>> list();
  Future<ChildProfile> getById(String id);
  Future<ChildProfile> create(ChildProfileDraft draft);
  Future<ChildProfile> update(String id, ChildProfileDraft draft);
  Future<void> archive(String id);
}

class RestChildProfilesRepository implements ChildProfilesRepository {
  RestChildProfilesRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;
  static const _basePath = '/api/v1/children';

  @override
  Future<List<ChildProfile>> list() async {
    final json = await _apiClient.get(_basePath);
    if (json is! List) throw const FormatException('Expected a child list.');
    return json
        .whereType<Map<String, dynamic>>()
        .map(ChildProfile.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ChildProfile> getById(String id) async =>
      ChildProfile.fromJson(await _map(await _apiClient.get('$_basePath/$id')));

  @override
  Future<ChildProfile> create(ChildProfileDraft draft) async =>
      ChildProfile.fromJson(
        await _map(await _apiClient.post(_basePath, draft.toJson())),
      );

  @override
  Future<ChildProfile> update(String id, ChildProfileDraft draft) async =>
      ChildProfile.fromJson(
        await _map(await _apiClient.put('$_basePath/$id', draft.toJson())),
      );

  @override
  Future<void> archive(String id) => _apiClient.delete('$_basePath/$id');

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected a child object.');
  }
}
