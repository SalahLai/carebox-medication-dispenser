import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/medication_provider.dart';
import '../services/api_service.dart';

class WifiConnectScreen extends StatefulWidget {
  const WifiConnectScreen({super.key});

  @override
  State<WifiConnectScreen> createState() => _WifiConnectScreenState();
}

class _WifiConnectScreenState extends State<WifiConnectScreen> {
  static const Color primaryBlue = Color(0xFF1259C3);
  static const Color scaffoldBg = Color(0xFFF1F3F5);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1D1D1D);
  static const Color textMuted = Color(0xFF6E6E6E);
  static const Color chipBlueBg = Color(0xFFEBF1FB);
  static const Color errorRed = Color(0xFFD32F2F);

  bool _isConnecting = false;

  Future<void> _handleConnect() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final isConnected = await ApiService.checkConnection();

      if (!mounted) return;

      if (isConnected) {
        // Load data from CareBox hardware into provider
        final provider = context.read<MedicationProvider>();
        bool syncFailed = false;
        try {
          await provider.loadFromDevice();
        } catch (_) {
          // Device is reachable (ping succeeded) but data sync failed.
          // Mark the provider as connected and navigate — local cache is used.
          provider.setConnected(true);
          syncFailed = true;
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');

        if (syncFailed) {
          // Show a subtle warning — not a blocking error.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Connected, but could not sync data from CareBox. Showing cached data.",
                style: GoogleFonts.outfit(fontSize: 13),
              ),
              backgroundColor: const Color(0xFF7A4F00),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        _showErrorSnackBar(
          "Could not reach CareBox. Make sure you're connected to the CareBox Wi-Fi network.",
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar(
        "Could not reach CareBox. Make sure you're connected to the CareBox Wi-Fi network.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Logo / Title
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: chipBlueBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.wifi_tethering_rounded,
                      size: 44,
                      color: primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "CareBox",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Smart Medication Dispenser",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 36),

                // Card with Two Numbered Steps
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CONNECT TO CAREBOX",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Step 1
                      _buildStepItem(
                        stepNumber: "1",
                        textSpan: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Open your phone ",
                            ),
                            TextSpan(
                              text: "Settings → Wi-Fi",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const TextSpan(
                              text: " → connect to ",
                            ),
                            TextSpan(
                              text: "'CareBox'",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                              ),
                            ),
                            const TextSpan(
                              text: "\n(password: ",
                            ),
                            TextSpan(
                              text: "carebox123",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const TextSpan(
                              text: ")",
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Divider(color: Color(0xFFF1F3F5), height: 1),
                      ),

                      // Step 2
                      _buildStepItem(
                        stepNumber: "2",
                        textSpan: const TextSpan(
                          text: "Tap Connect below",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Pill Button "Connect"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _handleConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      disabledBackgroundColor: const Color(0x991259C3),
                      foregroundColor: cardWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                    child: _isConnecting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cardWhite),
                            ),
                          )
                        : Text(
                            "Connect",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: textMuted,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Skip (testing)",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required InlineSpan textSpan,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: chipBlueBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: Text.rich(
              textSpan,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textDark,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
