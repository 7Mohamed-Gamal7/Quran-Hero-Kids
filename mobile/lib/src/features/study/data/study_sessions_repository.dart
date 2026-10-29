import '../../../core/network/api_client.dart';
import '../domain/study_session.dart';

abstract interface class StudySessionsRepository {
  Future<List<StudySessionRecord>> list(String childId);
  Future<StudySessionSummary> summary(String childId);
  Future<StudySessionRecord> record(String childId, StudySessionDraft draft);
}

class RestStudySessionsRepository implements StudySessionsRepository {
  RestStudySessionsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  String _path(String childId) =>
      '/api/v1/children/${Uri.encodeComponent(childId)}/study-sessions';

  @override
  Future<List<StudySessionRecord>> list(String childId) async {
    final value = await _apiClient.get(_path(childId));
    if (value is! List) {
      throw const FormatException('Expected a study session list.');
    }
    return value
        .map((item) => StudySessionRecord.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  @override
  Future<StudySessionSummary> summary(String childId) async {
    final value = await _apiClient.get('${_path(childId)}/summary');
    return StudySessionSummary.fromJson(_asMap(value));
  }

  @override
  Future<StudySessionRecord> record(
      String childId, StudySessionDraft draft) async {
    final value = await _apiClient.post(_path(childId), draft.toJson());
    return StudySessionRecord.fromJson(_asMap(value));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected a study session object.');
  }
}
