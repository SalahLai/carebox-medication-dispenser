import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/medication.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  static const Color primaryBlue = Color(0xFF1259C3);
  static const Color scaffoldBg = Color(0xFFF1F3F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1D1D1D);
  static const Color textMuted = Color(0xFF6E6E6E);
  static const Color borderOutline = Color(0xFFE5E5EA);
  static const Color placeholderColor = Color(0xFFBDBDBD);
  static const Color errorRed = Color(0xFFDC2626);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _selectedCompartment = 1;

  // Days array: index 0 = Mon, 6 = Sun  (matches Medication.days)
  final List<bool> _days = [true, true, true, true, true, false, false];
  final List<String> _dayLabels = [
    "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
  ];

  bool _isSaving = false;
  String? _nameError;
  String? _doseError;
  String? _daysError;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _toggleDay(int index) {
    setState(() {
      _days[index] = !_days[index];
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _pickCompartment() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Select Compartment",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
              for (int i = 1; i <= 4; i++)
                ListTile(
                  title: Text(
                    "Compartment $i",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: _selectedCompartment == i
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _selectedCompartment == i ? primaryBlue : textDark,
                    ),
                  ),
                  trailing: _selectedCompartment == i
                      ? const Icon(Icons.check, color: primaryBlue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCompartment = i;
                    });
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveMedication() async {
    // Validate
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();
    final atLeastOneDay = _days.any((d) => d);
    setState(() {
      _nameError = name.isEmpty ? "Please enter a medication name" : null;
      _doseError = dose.isEmpty ? "Please enter the dose" : null;
      _daysError = atLeastOneDay ? null : "Select at least one day";
    });
    if (_nameError != null || _doseError != null || _daysError != null) return;

    setState(() => _isSaving = true);

    final medication = Medication(
      name: name,
      dose: dose,
      time: _selectedTime,
      compartment: _selectedCompartment,
      days: List<bool>.from(_days),
    );

    try {
      await context.read<MedicationProvider>().addMedication(medication);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${medication.name} added to CareBox!",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Could not reach CareBox. Make sure you're connected to the CareBox Wi-Fi.",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime =
        "${_selectedTime.hourOfPeriod.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}";

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textDark,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add medication",
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Medication Name ──────────────────────────────────────────
              _buildFieldLabel("MEDICATION NAME"),
              Container(
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(12.0),
                  border: _nameError != null
                      ? Border.all(color: errorRed, width: 1.5)
                      : null,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "e.g. Lisinopril",
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: placeholderColor,
                    ),
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ),
              if (_nameError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                  child: Text(_nameError!,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: errorRed)),
                ),
              const SizedBox(height: 16),

              // ── Dose ─────────────────────────────────────────────────────
              _buildFieldLabel("DOSE"),
              Container(
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(12.0),
                  border: _doseError != null
                      ? Border.all(color: errorRed, width: 1.5)
                      : null,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  controller: _doseController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "e.g. 10mg, 1 tablet",
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: placeholderColor,
                    ),
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
              ),
              if (_doseError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                  child: Text(_doseError!,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: errorRed)),
                ),
              const SizedBox(height: 16),

              // ── Time & Compartment ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("TIME"),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: cardWhite,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textDark,
                                  ),
                                ),
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: Color(0xFF737784),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel("COMPARTMENT"),
                        InkWell(
                          onTap: _pickCompartment,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: cardWhite,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Compartment $_selectedCompartment",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textDark,
                                  ),
                                ),
                                const Icon(
                                  Icons.unfold_more_rounded,
                                  size: 18,
                                  color: Color(0xFF737784),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Repeat On ────────────────────────────────────────────────
              _buildFieldLabel("REPEAT ON"),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(_dayLabels.length, (i) {
                  final isSelected = _days[i];
                  return InkWell(
                    onTap: () => _toggleDay(i),
                    borderRadius: BorderRadius.circular(50.0),
                    child: Container(
                      height: 34,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : cardWhite,
                        borderRadius: BorderRadius.circular(50.0),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: borderOutline, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? cardWhite : textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_daysError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                  child: Text(_daysError!,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: errorRed)),
                ),
              const SizedBox(height: 32),

              // ── Save Button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: cardWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Send to CareBox",
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
