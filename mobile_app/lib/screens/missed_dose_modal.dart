import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/medication.dart';
import '../providers/medication_provider.dart';

class MissedDoseModal extends StatefulWidget {
  /// The medication whose dose was missed. If null the modal shows placeholder UI.
  final Medication? medication;

  const MissedDoseModal({super.key, this.medication});

  /// Convenience helper to show this modal as a dialog.
  static Future<void> show(BuildContext context, {Medication? medication}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x73000000),
      builder: (ctx) => MissedDoseModal(medication: medication),
    );
  }

  @override
  State<MissedDoseModal> createState() => _MissedDoseModalState();
}

class _MissedDoseModalState extends State<MissedDoseModal> {
  static const Color primaryBlue = Color(0xFF1259C3);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1D1D1D);
  static const Color textMuted = Color(0xFF6E6E6E);
  static const Color alertAmberBg = Color(0xFFFFF8E7);
  static const Color alertAmberIcon = Color(0xFFE5A000);
  static const Color boxBg = Color(0xFFF0EDED);
  static const Color secondaryBtnBg = Color(0xFFF1F3F5);

  bool _isTaking = false;

  Future<void> _handleTakeDose() async {
    final med = widget.medication;
    if (med == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isTaking = true);
    try {
      await context.read<MedicationProvider>().markAsTaken(med.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Dose taken confirmed. Caregiver alert cancelled.",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFF1B7A00),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTaking = false);
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
    final med = widget.medication;
    final medLabel = med != null ? '${med.name} ${med.dose}' : 'Amlodipine 5mg';
    final compLabel = med != null ? 'Compartment ${med.compartment}' : 'Compartment 1';
    final timeLabel = med != null
        ? '${med.time.hourOfPeriod.toString().padLeft(2, '0')}:${med.time.minute.toString().padLeft(2, '0')} ${med.time.period == DayPeriod.am ? 'AM' : 'PM'}'
        : '13:00';

    // Use Dialog so it layers correctly in the Material hierarchy.
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Amber Warning Circle
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: alertAmberBg,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.schedule_rounded,
                    color: alertAmberIcon,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Headline
              Text(
                "Missed Dose Alert",
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: textMuted,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(
                      text: '$medLabel ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    TextSpan(
                      text:
                          'was scheduled for $timeLabel ($compLabel). You missed this scheduled dose.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Compartment & Caregiver Status Highlight Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: boxBg,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_rounded,
                              color: primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              compLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(50.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            med?.dose ?? '1 Tablet',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFE5E2E1)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4.0),
                          decoration: const BoxDecoration(
                            color: alertAmberIcon,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Caregiver alert will be sent via SMS if unconfirmed.",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: textMuted,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Primary Action: Take Dose Now
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isTaking ? null : _handleTakeDose,
                  icon: _isTaking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: cardWhite,
                        ),
                  label: Text(
                    "Take Dose Now",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cardWhite,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    disabledBackgroundColor: const Color(0x991259C3),
                    foregroundColor: cardWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary Action: Skip This Dose
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: _isTaking ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: secondaryBtnBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                  child: Text(
                    "Skip This Dose",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
