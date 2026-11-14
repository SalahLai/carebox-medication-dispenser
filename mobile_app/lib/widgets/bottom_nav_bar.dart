import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class MainScaffoldScope extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainScaffoldScope({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required super.child,
  });

  static MainScaffoldScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainScaffoldScope>();
  }

  @override
  bool updateShouldNotify(MainScaffoldScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class CareBoxBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isRootNavBar;
  final ValueChanged<int>? onTabSelected;

  const CareBoxBottomNavBar({
    super.key,
    required this.currentIndex,
    this.isRootNavBar = false,
    this.onTabSelected,
  });

  static const Color activeColor = Color(0xFF1259C3);
  static const Color inactiveColor = Colors.grey;
  static const Color navBgColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE5E5EA);

  // IndexedStack has 3 slots: 0=Dashboard, 1=Medications, 2=Settings.
  // AddMedicationScreen is pushed via Navigator, not in the stack.
  static int mapNavIndexToStackIndex(int navIndex) => navIndex;

  static int mapStackIndexToNavIndex(int stackIndex) => stackIndex;

  @override
  Widget build(BuildContext context) {
    final scope = MainScaffoldScope.of(context);
    if (scope != null && !isRootNavBar) {
      return const SizedBox.shrink();
    }

    final effectiveIndex = isRootNavBar
        ? currentIndex
        : (scope != null ? mapStackIndexToNavIndex(scope.currentIndex) : currentIndex);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: navBgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            index: 0,
            icon: Symbols.home_rounded,
            label: 'Dashboard',
            route: '/dashboard',
            effectiveCurrentIndex: effectiveIndex,
            scope: scope,
          ),
          _buildNavItem(
            context: context,
            index: 1,
            icon: Symbols.pill_rounded,
            label: 'Medications',
            route: '/medications',
            effectiveCurrentIndex: effectiveIndex,
            scope: scope,
          ),
          _buildNavItem(
            context: context,
            index: 2,
            icon: Symbols.settings_rounded,
            label: 'Settings',
            route: '/settings',
            effectiveCurrentIndex: effectiveIndex,
            scope: scope,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required String route,
    required int effectiveCurrentIndex,
    required MainScaffoldScope? scope,
  }) {
    final bool isActive = effectiveCurrentIndex == index;
    final Color itemColor = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) {
            if (onTabSelected != null) {
              onTabSelected!(index);
            } else if (scope != null) {
              scope.onTabSelected(mapNavIndexToStackIndex(index));
            } else {
              Navigator.pushReplacementNamed(context, route);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isActive ? 26 : 24,
                color: itemColor,
                fill: 1.0,
                weight: isActive ? 600 : 500,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: itemColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
