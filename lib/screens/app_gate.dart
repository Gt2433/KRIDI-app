import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'main_nav_screen.dart';

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  /// In-memory flag tracking guest access for this app run only.
  /// Reset to false when the app closes or user logs out.
  static bool guestSessionActive = false;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: AuthService.userNotifier,
      builder: (context, user, _) {
        // If user is authenticated with Firebase account: direct access
        if (user != null) {
          return const MainNavScreen();
        }

        // If user explicitly chose to continue as guest during this runtime session
        if (AppGate.guestSessionActive) {
          return const MainNavScreen();
        }

        // First launch, or reopening app without an account: show AuthScreen
        return AuthScreen(
          isModal: false,
          onContinueAsGuest: () {
            setState(() {
              AppGate.guestSessionActive = true;
            });
          },
        );
      },
    );
  }
}

