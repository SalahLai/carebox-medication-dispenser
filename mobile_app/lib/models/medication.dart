import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents a scheduled medication in the CareBox system.
class Medication {
  final String id;
  final String name;
  final String dose;
  final TimeOfDay time;
  final int compartment;

  /// 7 booleans representing Mon–Sun (index 0 = Monday, 6 = Sunday).
  final List<bool> days;

  Medication({
    String? id,
    required this.name,
    required this.dose,
    required this.time,
    required this.compartment,
    required this.days,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'hour': time.hour,
        'minute': time.minute,
        'timeHour': time.hour,
        'timeMinute': time.minute,
        'compartment': compartment,
        'days': days,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        dose: (json['dose'] ?? '') as String,
        time: TimeOfDay(
          hour: ((json['hour'] ?? json['timeHour']) ?? 0) as int,
          minute: ((json['minute'] ?? json['timeMinute']) ?? 0) as int,
        ),
        compartment: (json['compartment'] ?? 1) as int,
        days: json['days'] != null
            ? List<bool>.from(json['days'] as List)
            : List<bool>.filled(7, true),
      );

  /// Serialises this medication to a JSON string for [SharedPreferences].
  String toJsonString() => jsonEncode(toJson());

  /// Deserialises a medication from a JSON string stored in [SharedPreferences].
  factory Medication.fromJsonString(String source) =>
      Medication.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Returns a copy of this medication with optional field overrides.
  Medication copyWith({
    String? name,
    String? dose,
    TimeOfDay? time,
    int? compartment,
    List<bool>? days,
  }) =>
      Medication(
        id: id,
        name: name ?? this.name,
        dose: dose ?? this.dose,
        time: time ?? this.time,
        compartment: compartment ?? this.compartment,
        days: days ?? List<bool>.from(this.days),
      );
}
