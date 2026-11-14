import 'package:carebox/models/dose_log.dart';
import 'package:carebox/models/medication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Medication Model serialization', () {
    test('toJson produces keys matching ESP32 firmware expectations', () {
      final med = Medication(
        id: 'test-123',
        name: 'Aspirin',
        dose: '100mg',
        time: const TimeOfDay(hour: 8, minute: 30),
        compartment: 2,
        days: [true, true, true, true, true, false, false],
      );

      final json = med.toJson();

      // Required by ESP32 handleAddMedication():
      expect(json['id'], 'test-123');
      expect(json['name'], 'Aspirin');
      expect(json['dose'], '100mg');
      expect(json['hour'], 8);
      expect(json['minute'], 30);
      expect(json['compartment'], 2);
      expect(json['days'], [true, true, true, true, true, false, false]);

      // Legacy keys for backwards compatibility:
      expect(json['timeHour'], 8);
      expect(json['timeMinute'], 30);
    });

    test('fromJson parses ESP32 GET /medications response', () {
      final esp32Json = {
        'id': 'med-1',
        'name': 'Doliprane',
        'dose': '1000mg',
        'hour': 14,
        'minute': 15,
        'compartment': 3,
        'days': [false, true, false, true, false, true, false],
      };

      final med = Medication.fromJson(esp32Json);

      expect(med.id, 'med-1');
      expect(med.name, 'Doliprane');
      expect(med.dose, '1000mg');
      expect(med.time.hour, 14);
      expect(med.time.minute, 15);
      expect(med.compartment, 3);
      expect(med.days, [false, true, false, true, false, true, false]);
    });

    test('fromJson parses legacy local SharedPreferences cache format', () {
      final legacyJson = {
        'id': 'legacy-1',
        'name': 'Paracetamol',
        'dose': '500mg',
        'timeHour': 20,
        'timeMinute': 45,
        'compartment': 1,
        'days': [true, true, true, true, true, true, true],
      };

      final med = Medication.fromJson(legacyJson);

      expect(med.id, 'legacy-1');
      expect(med.time.hour, 20);
      expect(med.time.minute, 45);
    });
  });

  group('DoseLog Model serialization', () {
    test('fromJson parses ESP32 GET /logs response missing scheduledTime', () {
      final esp32LogJson = {
        'medicationId': 'med-1',
        'medicationName': 'Doliprane',
        'status': 'taken',
      };

      final log = DoseLog.fromJson(esp32LogJson);

      expect(log.medicationId, 'med-1');
      expect(log.medicationName, 'Doliprane');
      expect(log.status, DoseStatus.taken);
      expect(log.scheduledTime, isNotNull);
      expect(log.confirmedAt, isNull);
    });
  });
}
