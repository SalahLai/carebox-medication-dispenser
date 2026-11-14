import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  static const Color primaryBlue = Color(0xFF1259C3);
  static const Color scaffoldBg = Color(0xFFF1F3F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1D1D1D);
  static const Color textMuted = Color(0xFF6E6E6E);
  static const Color dividerColor = Color(0xFFF1F3F5);
  static const Color chevronColor = Color(0xFFCACACA);

  // Cycling tint colors for medication icons
  static const List<Color> _iconBgColors = [
    Color(0xFFEBF1FB),
    Color(0xFFEAF7E8),
    Color(0xFFFFF8E7),
    Color(0xFFF3EEFF),
    Color(0xFFFFEEEE),
  ];
  static const List<Color> _iconColors = [
    Color(0xFF1259C3),
    Color(0xFF2DB400),
    Color(0xFFE5A000),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, provider, _) {
        final meds = provider.medications;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page title ─────────────────────────────────────────
                  Text(
                    "Medications",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Medications list ───────────────────────────────────
                  if (meds.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          "No medications yet.\nTap \"Add medication\" below to get started.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 14,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < meds.length; i++) ...[
                            if (i != 0)
                              const Divider(height: 1, color: dividerColor),
                            _buildMedicationRow(
                              context: context,
                              med: meds[i],
                              provider: provider,
                              iconBgColor:
                                  _iconBgColors[i % _iconBgColors.length],
                              iconColor: _iconColors[i % _iconColors.length],
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  // ── Add medication button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_medication');
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: cardWhite,
                      ),
                      label: Text(
                        "Add medication",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cardWhite,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: cardWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const CareBoxBottomNavBar(currentIndex: 1),
        );
      },
    );
  }

  Widget _buildMedicationRow({
    required BuildContext context,
    required Medication med,
    required MedicationProvider provider,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final hour = med.time.hourOfPeriod.toString().padLeft(2, '0');
    final min = med.time.minute.toString().padLeft(2, '0');
    final period = med.time.period == DayPeriod.am ? 'AM' : 'PM';
    final details =
        "${med.dose} · $hour:$min $period · Compartment ${med.compartment}";

    return InkWell(
      onTap: null,
      onLongPress: () => _confirmDelete(context, provider, med),
      borderRadius: BorderRadius.circular(24.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Symbols.pill,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron removed — no detail screen implemented yet.
            // Long-press to delete is indicated by the hold gesture.
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MedicationProvider provider,
    Medication med,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(
              "Remove ${med.name}?",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            content: Text(
              "This will remove the medication from your schedule.",
              style: GoogleFonts.outfit(),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: Text("Cancel", style: GoogleFonts.outfit()),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await provider.deleteMedication(med.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (_) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
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
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "Remove",
                        style: GoogleFonts.outfit(
                            color: const Color(0xFFDC2626)),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
