import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/dose_log.dart';
import '../providers/medication_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Non-null while a markAsTaken API call is in flight.
  String? _markingTakenId;

  static const Color primaryBlue = Color(0xFF1259C3);
  static const Color scaffoldBg = Color(0xFFF1F3F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1D1D1D);
  static const Color textMuted = Color(0xFF6E6E6E);
  static const Color dividerColor = Color(0xFFF1F3F5);

  // Status Chip Colors
  static const Color badgeTakenBg = Color(0xFFEAF7E8);
  static const Color badgeTakenText = Color(0xFF1B7A00);
  static const Color badgeTakenDot = Color(0xFF2DB400);

  static const Color badgeDueBg = Color(0xFFFFF8E7);
  static const Color badgeDueText = Color(0xFF7A4F00);
  static const Color badgeDueDot = Color(0xFFD97706);

  static const Color badgeMissedBg = Color(0xFFFEE2E2);
  static const Color badgeMissedText = Color(0xFFDC2626);

  static const Color badgeUpcomingBg = Color(0xFFF1F3F5);
  static const Color badgeUpcomingText = Color(0xFF6E6E6E);

  static const Color badgeSkippedBg = Color(0xFFF3F4F6);
  static const Color badgeSkippedText = Color(0xFF4B5563);

  static const Color connectedBg = Color(0xFFEAF7E8);
  static const Color disconnectedBg = Color(0xFFFEE2E2);
  static const Color disconnectedText = Color(0xFFDC2626);
  static const Color disconnectedDot = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, provider, _) {
        final nextDose = provider.nextDose;
        final minsUntil = provider.minutesUntilNextDose;        final taken = provider.takenTodayCount;
        final total = provider.totalTodayCount;
        final progress = total == 0 ? 0.0 : taken / total;
        final isConnected = provider.isConnected;
        final history = provider.recentHistory;

        // Format today's date label
        final now = DateTime.now();
        final dayNames = [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday',
          'Friday', 'Saturday', 'Sunday',
        ];
        final monthNames = [
          '', 'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];
        final dateLabel =
            '${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month]}';

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CareBox",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Connection badge driven by provider
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        decoration: BoxDecoration(
                          color: isConnected ? connectedBg : disconnectedBg,
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? badgeTakenDot
                                    : disconnectedDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected ? "Connected" : "Disconnected",
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isConnected
                                    ? badgeTakenText
                                    : disconnectedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Progress bar ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        total == 0
                            ? "No doses scheduled today"
                            : "$taken of $total doses taken today",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                      Text(
                        total == 0
                            ? ""
                            : "${(progress * 100).round()}%",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFE8EEFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Next Dose hero card ─────────────────────────────────
                  if (nextDose != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F1259C3),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "NEXT DOSE",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                minsUntil == 0
                                    ? "DUE NOW"
                                    : minsUntil != null && minsUntil <= 60
                                        ? "IN $minsUntil MIN"
                                        : "${nextDose.time.hourOfPeriod.toString().padLeft(2, '0')}:${nextDose.time.minute.toString().padLeft(2, '0')} ${nextDose.time.period == DayPeriod.am ? 'AM' : 'PM'}",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${nextDose.name} ${nextDose.dose}",
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: cardWhite,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${nextDose.dose} · Compartment ${nextDose.compartment}",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _markingTakenId != null
                                  ? null
                                  : () async {
                                      setState(() =>
                                          _markingTakenId = nextDose.id);
                                      try {
                                        await provider
                                            .markAsTaken(nextDose.id);
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Could not reach CareBox. Make sure you're connected to the CareBox Wi-Fi.",
                                                style: GoogleFonts.outfit(),
                                              ),
                                              backgroundColor:
                                                  const Color(0xFFD32F2F),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(
                                              () => _markingTakenId = null);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cardWhite,
                                foregroundColor: primaryBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.0),
                                ),
                              ),
                              child: _markingTakenId == nextDose.id
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryBlue),
                                      ),
                                    )
                                  : Text(
                                      "Mark as Taken",
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: primaryBlue,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: badgeTakenBg,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        total == 0
                            ? "No medications scheduled — add one on the Medications tab."
                            : "All done for today! Great job. 🎉",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: badgeTakenText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // ── Recent History ──────────────────────────────────────
                  if (history.isNotEmpty) ...[
                    Text(
                      "RECENT HISTORY",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < history.length; i++) ...[
                            if (i != 0)
                              const Divider(height: 1, color: dividerColor),
                            _buildHistoryRow(history[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: const CareBoxBottomNavBar(currentIndex: 0),
        );
      },
    );
  }

  Widget _buildHistoryRow(DoseLog log) {
    final t = log.scheduledTime;
    final hour = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final isToday = t.year == now.year &&
        t.month == now.month &&
        t.day == now.day;
    final isYesterday = t.day == now.subtract(const Duration(days: 1)).day &&
        t.month == now.subtract(const Duration(days: 1)).month &&
        t.year == now.subtract(const Duration(days: 1)).year;

    String dayLabel;
    if (isToday) {
      dayLabel = "Today, $hour:$min";
    } else if (isYesterday) {
      dayLabel = "Yesterday, $hour:$min";
    } else {
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      dayLabel = "${t.day} ${months[t.month]}, $hour:$min";
    }

    Color chipBg;
    Color chipText;
    String chipLabel;
    switch (log.status) {
      case DoseStatus.taken:
        chipBg = badgeTakenBg;
        chipText = badgeTakenText;
        chipLabel = "Taken";
      case DoseStatus.missed:
        chipBg = badgeMissedBg;
        chipText = badgeMissedText;
        chipLabel = "Missed";
      case DoseStatus.skipped:
        chipBg = badgeSkippedBg;
        chipText = badgeSkippedText;
        chipLabel = "Skipped";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayLabel,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    log.medicationName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(50.0),
            ),
            child: Text(
              chipLabel,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: chipText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
