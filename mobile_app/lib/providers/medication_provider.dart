import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dose_log.dart';
import '../models/medication.dart';
import '../services/api_service.dart';

class MedicationProvider extends ChangeNotifier {
  // ── State ────────────────────────────────────────────────────────────────

  List<Medication> _medications = [];
  List<DoseLog> _recentHistory = [];
  bool _isConnected = false;

  // ── Public getters ───────────────────────────────────────────────────────

  List<Medication> get medications => List.unmodifiable(_medications);
  List<DoseLog> get recentHistory => List.unmodifiable(_recentHistory);
  bool get isConnected => _isConnected;

  /// The next scheduled dose for today, or null if none remain.
  Medication? get nextDose {
    final now = TimeOfDay.now();
    final todayIndex = _todayWeekdayIndex();

    // Filter medications active today, scheduled at or after current time
    final upcoming = _medications.where((m) {
      if (!m.days[todayIndex]) return false;
      final mMins = m.time.hour * 60 + m.time.minute;
      final nowMins = now.hour * 60 + now.minute;
      return mMins >= nowMins;
    }).toList()
      ..sort((a, b) {
        final aM = a.time.hour * 60 + a.time.minute;
        final bM = b.time.hour * 60 + b.time.minute;
        return aM.compareTo(bM);
      });

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Minutes until [nextDose] is due, or null if there is no next dose.
  int? get minutesUntilNextDose {
    final next = nextDose;
    if (next == null) return null;
    final now = TimeOfDay.now();
    return (next.time.hour * 60 + next.time.minute) -
        (now.hour * 60 + now.minute);
  }

  /// Count of today's doses that have been marked taken.
  int get takenTodayCount {
    final today = DateTime.now();
    return _recentHistory.where((log) {
      return log.status == DoseStatus.taken &&
          log.scheduledTime.year == today.year &&
          log.scheduledTime.month == today.month &&
          log.scheduledTime.day == today.day;
    }).length;
  }

  /// Count of today's total scheduled doses.
  int get totalTodayCount {
    final todayIndex = _todayWeekdayIndex();
    return _medications.where((m) => m.days[todayIndex]).length;
  }

  // ── SharedPreferences keys ───────────────────────────────────────────────

  static const String _kMedications = 'medications_v1';
  static const String _kHistory = 'dose_history_v1';

  // ── Public methods ───────────────────────────────────────────────────────

  /// Loads medications and dose history from local cache (SharedPreferences).
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final medStrings = prefs.getStringList(_kMedications) ?? [];
    _medications = medStrings.map((s) => Medication.fromJsonString(s)).toList();

    final histStrings = prefs.getStringList(_kHistory) ?? [];
    _recentHistory =
        histStrings.map((s) => DoseLog.fromJsonString(s)).toList();

    notifyListeners();
  }

  /// Synchronises time and loads medications list directly from CareBox hardware.
  Future<void> loadFromDevice() async {
    await ApiService.syncTime();
    final meds = await ApiService.getMedications();
    _medications = meds;
    await _saveMedications();

    try {
      final logs = await ApiService.getLogs();
      _recentHistory = logs;
      await _saveHistory();
    } catch (_) {
      // Ignore if logs endpoint is optional or empty
    }

    _isConnected = true;
    notifyListeners();
  }

  /// Refreshes medications from CareBox hardware and updates local cache.
  Future<void> refresh() async {
    final meds = await ApiService.getMedications();
    _medications = meds;
    await _saveMedications();

    try {
      // Replace history with device data regardless of whether it is empty.
      // An empty list from a freshly reset device is valid.
      final logs = await ApiService.getLogs();
      _recentHistory = logs;
      await _saveHistory();
    } catch (_) {
      // Retain existing local logs if getLogs throws (e.g. network error).
    }

    notifyListeners();
  }

  /// Adds a medication on CareBox and refreshes from device.
  Future<void> addMedication(Medication m) async {
    await ApiService.addMedication(m);
    await refresh();
  }

  /// Removes a medication on CareBox by id and refreshes from device.
  Future<void> deleteMedication(String id) async {
    await ApiService.deleteMedication(id);
    await refresh();
  }

  /// Records a dose as taken on CareBox and updates local history optimistically.
  /// Refreshes medications list from device after confirming with the API.
  Future<void> markAsTaken(String medicationId) async {
    await ApiService.markAsTaken(medicationId);

    // Optimistically add a local log entry so the dashboard updates immediately.
    final med =
        _medications.where((m) => m.id == medicationId).firstOrNull;
    if (med != null) {
      final log = DoseLog(
        medicationId: medicationId,
        medicationName: med.name,
        scheduledTime: _scheduledTimeForToday(med.time),
        status: DoseStatus.taken,
        confirmedAt: DateTime.now(),
      );
      // Remove any existing entry for the same dose slot before inserting.
      _recentHistory.removeWhere((l) =>
          l.medicationId == medicationId &&
          l.scheduledTime.year == log.scheduledTime.year &&
          l.scheduledTime.month == log.scheduledTime.month &&
          l.scheduledTime.day == log.scheduledTime.day &&
          l.scheduledTime.hour == log.scheduledTime.hour &&
          l.scheduledTime.minute == log.scheduledTime.minute);
      _recentHistory.insert(0, log);
      await _saveHistory();
    }

    // Refresh medication list only (not history — we already have the correct
    // local optimistic entry; the device log lacks scheduledTime detail).
    try {
      final meds = await ApiService.getMedications();
      _medications = meds;
      await _saveMedications();
    } catch (_) {
      // Keep the local list if refresh fails; optimistic entry is already saved.
    }

    notifyListeners();
  }

  /// Updates connection status and notifies listeners.
  void setConnected(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Returns 0-based weekday index matching [Medication.days] (Mon = 0).
  int _todayWeekdayIndex() {
    // DateTime.weekday: 1 = Monday, 7 = Sunday → convert to 0-based Mon-first
    return DateTime.now().weekday - 1;
  }

  /// Combines today's date with a [TimeOfDay] to produce a [DateTime].
  DateTime _scheduledTimeForToday(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kMedications,
      _medications.map((m) => m.toJsonString()).toList(),
    );
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only the last 50 entries to bound storage size
    final toSave = _recentHistory.take(50).toList();
    await prefs.setStringList(
      _kHistory,
      toSave.map((l) => l.toJsonString()).toList(),
    );
  }
}
