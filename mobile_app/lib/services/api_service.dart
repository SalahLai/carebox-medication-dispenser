import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/dose_log.dart';
import '../models/medication.dart';

const String _baseUrl = 'http://192.168.4.1';

class ApiService {
  static const Duration _timeout = Duration(seconds: 5);

  /// Checks Wi-Fi connection to CareBox AP.
  /// Returns true if GET /status returns 200, false on any error.
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/status'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Synchronises device time with the current Unix timestamp in seconds.
  static Future<void> syncTime() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final response = await http
          .post(
            Uri.parse('$_baseUrl/time'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'timestamp': timestamp}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception('Failed to sync time (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error syncing time: $e');
    }
  }

  /// Retrieves list of medications from CareBox.
  static Future<List<Medication>> getMedications() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/medications'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list;
        if (data is Map<String, dynamic> && data.containsKey('medications')) {
          list = data['medications'] as List<dynamic>;
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        return list
            .map((item) => Medication.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to get medications (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error getting medications: $e');
    }
  }

  /// Adds a new medication schedule to CareBox.
  static Future<void> addMedication(Medication m) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/medications'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(m.toJson()),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to add medication (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error adding medication: $e');
    }
  }

  /// Deletes a medication schedule from CareBox by ID.
  static Future<void> deleteMedication(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/medications/$id'))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete medication (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error deleting medication: $e');
    }
  }

  /// Marks a medication dose as taken on CareBox.
  static Future<void> markAsTaken(String id) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/medications/$id/taken'))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to mark medication as taken (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error marking medication as taken: $e');
    }
  }

  /// Retrieves dose history logs from CareBox.
  static Future<List<DoseLog>> getLogs() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/logs')).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list;
        if (data is Map<String, dynamic> && data.containsKey('logs')) {
          list = data['logs'] as List<dynamic>;
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        return list
            .map((item) => DoseLog.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to get logs (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error getting logs: $e');
    }
  }

  /// Saves caregiver settings to CareBox.
  static Future<void> saveSettings(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/settings'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'caregiverPhone': phone}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to save settings (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error saving settings: $e');
    }
  }

  /// Retrieves caregiver settings from CareBox.
  static Future<String?> getSettings() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/settings')).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data['caregiverPhone'] as String?;
        }
        return null;
      } else {
        throw Exception(
            'Failed to get settings (status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error getting settings: $e');
    }
  }
}
