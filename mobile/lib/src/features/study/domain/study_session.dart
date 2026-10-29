import 'dart:math';

/// Session categories accepted by the API. Keep names aligned with its JSON contract.
enum StudySessionKind { memorization, revision, test }

extension StudySessionKindLabel on StudySessionKind {
  String get label => switch (this) {
        StudySessionKind.memorization => 'حفظ',
        StudySessionKind.revision => 'مراجعة',
        StudySessionKind.test => 'اختبار',
      };
}

class StudySessionRecord {
  const StudySessionRecord({
    required this.id,
    required this.clientEventId,
    required this.kind,
    required this.durationSeconds,
    required this.occurredAt,
    required this.receivedAt,
  });

  final String id;
  final String clientEventId;
  final StudySessionKind kind;
  final int durationSeconds;
  final DateTime occurredAt;
  final DateTime receivedAt;

  factory StudySessionRecord.fromJson(Map<String, dynamic> json) {
    final kindValue = json['kind'];
    final kind = StudySessionKind.values.where(
      (value) => value.name == kindValue?.toString().toLowerCase(),
    );
    if (kindValue is! String || kind.isEmpty) {
      throw const FormatException('Unknown study session kind.');
    }
    final duration = json['durationSeconds'];
    if (duration is! int || duration < 1 || duration > 28800) {
      throw const FormatException('Invalid study session duration.');
    }
    return StudySessionRecord(
      id: _requiredString(json, 'id'),
      clientEventId: _requiredString(json, 'clientEventId'),
      kind: kind.first,
      durationSeconds: duration,
      occurredAt: DateTime.parse(_requiredString(json, 'occurredAt')),
      receivedAt: DateTime.parse(_requiredString(json, 'receivedAt')),
    );
  }
}

class StudySessionSummary {
  const StudySessionSummary({
    required this.sessionCount,
    required this.totalDurationSeconds,
  });

  final int sessionCount;
  final int totalDurationSeconds;

  factory StudySessionSummary.fromJson(Map<String, dynamic> json) {
    final sessionCount = json['sessionCount'];
    final totalDurationSeconds = json['totalDurationSeconds'];
    if (sessionCount is! int ||
        sessionCount < 0 ||
        totalDurationSeconds is! int ||
        totalDurationSeconds < 0) {
      throw const FormatException('Invalid study session summary.');
    }
    return StudySessionSummary(
      sessionCount: sessionCount,
      totalDurationSeconds: totalDurationSeconds,
    );
  }
}

/// Immutable payload created once when a timer finishes and retained for retries.
class StudySessionDraft {
  StudySessionDraft({
    required this.clientEventId,
    required this.kind,
    required this.durationSeconds,
    required this.occurredAt,
  }) {
    if (clientEventId.isEmpty) throw ArgumentError.value(clientEventId);
    if (durationSeconds < 1 || durationSeconds > 28800) {
      throw RangeError.range(durationSeconds, 1, 28800, 'durationSeconds');
    }
  }

  factory StudySessionDraft.create({
    required StudySessionKind kind,
    required int durationSeconds,
    required DateTime occurredAt,
    Random? random,
  }) =>
      StudySessionDraft(
        clientEventId: _newUuidV4(random ?? Random.secure()),
        kind: kind,
        durationSeconds: durationSeconds,
        occurredAt: occurredAt.toUtc(),
      );

  final String clientEventId;
  final StudySessionKind kind;
  final int durationSeconds;
  final DateTime occurredAt;

  Map<String, Object> toJson() => {
        'clientEventId': clientEventId,
        'kind': kind.name,
        'durationSeconds': durationSeconds,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
      };
}

String _newUuidV4(Random random) {
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing study session field: $key.');
  }
  return value;
}
