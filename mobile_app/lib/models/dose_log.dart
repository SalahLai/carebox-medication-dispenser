import 'dart:convert';

/// Possible statuses for a scheduled dose event.
enum DoseStatus { taken, missed, skipped }

/// Records the outcome of a single scheduled dose event.
class DoseLog {
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final DoseStatus status;
  final DateTime? confirmedAt;

  const DoseLog({
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    required this.status,
    this.confirmedAt,
  });

  Map<String, dynamic> toJson() => {
        'medicationId': medicationId,
        'medicationName': medicationName,
        'scheduledTime': scheduledTime.toIso8601String(),
        'status': status.name,
        'confirmedAt': confirmedAt?.toIso8601String(),
      };

  factory DoseLog.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic value) {
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return DateTime.now();
    }

    DoseStatus parseStatus(dynamic value) {
      if (value is String) {
        try {
          return DoseStatus.values.byName(value.toLowerCase());
        } catch (_) {}
      }
      return DoseStatus.taken;
    }

    return DoseLog(
      medicationId: (json['medicationId'] ?? '') as String,
      medicationName: (json['medicationName'] ?? '') as String,
      scheduledTime: parseTime(json['scheduledTime']),
      status: parseStatus(json['status']),
      confirmedAt: json['confirmedAt'] != null &&
              (json['confirmedAt'] as String).isNotEmpty
          ? DateTime.tryParse(json['confirmedAt'] as String)
          : null,
    );
  }

  /// Serialises this log entry to a JSON string for [SharedPreferences].
  String toJsonString() => jsonEncode(toJson());

  /// Deserialises a log entry from a JSON string stored in [SharedPreferences].
  factory DoseLog.fromJsonString(String source) =>
      DoseLog.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
