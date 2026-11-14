import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/medication_provider.dart';
import 'screens/wifi_connect_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/add_medication_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/missed_dose_modal.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final provider = MedicationProvider();
  await provider.loadFromStorage();

  runApp(
    ChangeNotifierProvider<MedicationProvider>.value(
      value: provider,
      child: const CareBoxApp(),
    ),
  );
}

class CareBoxApp extends StatelessWidget {
  const CareBoxApp({super.key});

  static const Color primaryCobalt = Color(0xFF1259C3);
  static const Color scaffoldBackground = Color(0xFFF1F3F5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryCobalt,
        scaffoldBackgroundColor: scaffoldBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryCobalt,
          primary: primaryCobalt,
          surface: scaffoldBackground,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: '/wifi_connect',
      routes: {
        '/wifi_connect': (context) => const WifiConnectScreen(),
        '/bluetooth_pairing': (context) => const WifiConnectScreen(),
        '/dashboard': (context) => const MainScaffold(initialIndex: 0),
        '/medications': (context) => const MainScaffold(initialIndex: 1),
        // /add_medication is pushed on top of MainScaffold via Navigator.push,
        // not hosted in IndexedStack, so it uses a standalone route here.
        '/add_medication': (context) => const AddMedicationScreen(),
        '/settings': (context) => const MainScaffold(initialIndex: 2),
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int stackIndex) {
    if (_currentIndex != stackIndex) {
      setState(() {
        _currentIndex = stackIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffoldScope(
      currentIndex: _currentIndex,
      onTabSelected: _onTabSelected,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            DashboardScreen(),
            MedicationsScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: CareBoxBottomNavBar(
          currentIndex: _currentIndex,
          isRootNavBar: true,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
