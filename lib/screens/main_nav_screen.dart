import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../widgets/action_choice_sheet.dart';
import '../widgets/pin_lock_screen.dart';
import 'settings_screen.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/debts_tab.dart';
import 'tabs/transactions_tab.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    // Check PIN lock
    if (SettingsService.pinEnabledNotifier.value && !SettingsService.isUnlockedThisSession) {
      _isLocked = true;
    }

    // Auto-check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context, isManualCheck: false);
    });
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'الرئيسية';
      case 1:
        return 'المعاملات';
      case 2:
        return 'الديون';
      case 3:
        return 'التقارير';
      default:
        return 'الرئيسية';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);
    final buttonBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB);
    final textCol = isDark ? Colors.white : Colors.black;

    // If locked by PIN
    if (_isLocked) {
      return PinLockScreen(
        onUnlocked: () {
          setState(() => _isLocked = false);
        },
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          _appBarTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textCol,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // Quick Theme Toggle Button (🌙 / ☀️)
          ValueListenableBuilder<ThemeMode>(
            valueListenable: SettingsService.themeModeNotifier,
            builder: (context, mode, _) {
              final isDarkMode = mode == ThemeMode.dark;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: buttonBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderCol, width: 1.2),
                ),
                child: IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                    size: 19,
                    color: isDarkMode ? const Color(0xFFFBBF24) : Colors.black,
                  ),
                  tooltip: isDarkMode ? 'الوضع المضيء' : 'الوضع المظلم',
                  onPressed: () => SettingsService.toggleThemeMode(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Currency Pill
          ValueListenableBuilder<String>(
            valueListenable: SettingsService.currencyNotifier,
            builder: (context, curr, _) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: buttonBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderCol,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    curr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Settings Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: buttonBg,
              shape: BoxShape.circle,
              border: Border.all(color: borderCol, width: 1.2),
            ),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, size: 20, color: textCol),
              tooltip: 'الإعدادات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Container(
        color: scaffoldBg,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardTab(
              onSeeAllTransactions: () => _onTabSelected(1),
              onSeeAllDebts: () => _onTabSelected(2),
            ),
            const TransactionsTab(),
            const DebtsTab(),
            const AnalyticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: borderCol,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withAlpha(60) : Colors.black.withAlpha(14),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'الرئيسية', isDark),
                _buildNavItem(1, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'المعاملات', isDark),
                _buildCenterFab(context, isDark),
                _buildNavItem(2, Icons.handshake_rounded, Icons.handshake_outlined, 'الديون', isDark),
                _buildNavItem(3, Icons.pie_chart_rounded, Icons.pie_chart_outline_rounded, 'التقارير', isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFab(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => ActionChoiceSheet.show(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: isDark ? Colors.black : Colors.white, size: 28),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF));

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
