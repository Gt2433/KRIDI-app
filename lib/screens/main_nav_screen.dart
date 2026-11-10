import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../widgets/action_choice_sheet.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/pin_lock_screen.dart';
import '../widgets/profile_bottom_sheet.dart';
import '../widgets/user_avatar.dart';
import 'auth_screen.dart';
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
        return 'كريدي';
      case 1:
        return 'المعاملات';
      case 2:
        return 'الديون';
      case 3:
        return 'التقارير';
      default:
        return 'كريدي';
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
          // Profile Button
          ValueListenableBuilder<User?>(
            valueListenable: AuthService.userNotifier,
            builder: (context, user, _) {
              final isLogged = user != null;
              final displayName = user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : (user?.email?.split('@').first ?? '');

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: buttonBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLogged ? const Color(0xFF16A34A).withAlpha(120) : borderCol,
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: isLogged
                          ? UserAvatar(
                              size: 26,
                              photoUrl: user.photoURL,
                              name: displayName,
                            )
                          : Icon(Icons.person_outline_rounded, size: 20, color: textCol),
                      tooltip: isLogged ? displayName : 'تسجيل الدخول / إنشاء حساب',
                      onPressed: () {
                        if (isLogged) {
                          ProfileBottomSheet.show(context, user);
                        } else {
                          AuthScreen.show(context);
                        }
                      },
                    ),
                    if (isLogged)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _buildCurrentTab(),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF141416) : Colors.white).withAlpha(isDark ? 230 : 240),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 90 : 15),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 4 Navigation tabs distributed with mathematical symmetry
                    Row(
                      children: [
                        Expanded(child: _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'الرئيسية', isDark)),
                        Expanded(child: _buildNavItem(1, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'المعاملات', isDark)),
                        const SizedBox(width: 58), // Exact reserved space for center FAB
                        Expanded(child: _buildNavItem(2, Icons.handshake_rounded, Icons.handshake_outlined, 'الديون', isDark)),
                        Expanded(child: _buildNavItem(3, Icons.pie_chart_rounded, Icons.pie_chart_outline_rounded, 'التقارير', isDark)),
                      ],
                    ),

                    // Guaranteed dead-center + action button
                    Center(
                      child: _buildCenterFab(context, isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return DashboardTab(
          onSeeAllTransactions: () => _onTabSelected(1),
          onSeeAllDebts: () => _onTabSelected(2),
        );
      case 1:
        return const TransactionsTab();
      case 2:
        return const DebtsTab();
      case 3:
        return const AnalyticsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCenterFab(BuildContext context, bool isDark) {
    return BouncingButton(
      scaleFactor: 0.86,
      onTap: () => ActionChoiceSheet.show(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withAlpha(isDark ? 45 : 35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: isDark ? Colors.black : Colors.white,
          size: 27,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);
    final color = isSelected ? activeColor : inactiveColor;

    return BouncingButton(
      scaleFactor: 0.90,
      onTap: () => _onTabSelected(index),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.14 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  key: ValueKey<bool>(isSelected),
                  color: color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
                fontFamily: 'Cairo',
              ),
              child: Text(label),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isSelected ? 16 : 0,
              height: isSelected ? 2.5 : 0,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
