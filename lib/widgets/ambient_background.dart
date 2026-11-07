import 'dart:ui';
import 'package:flutter/material.dart';

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base solid background
        Container(
          color: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
        ),

        // Ambient Glowing Orb 1 (Top Left)
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF0D9488).withAlpha(45) // Teal
                  : const Color(0xFF0D9488).withAlpha(35),
            ),
          ),
        ),

        // Ambient Glowing Orb 2 (Center Right)
        Positioned(
          top: 220,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF6366F1).withAlpha(35) // Indigo
                  : const Color(0xFF818CF8).withAlpha(30),
            ),
          ),
        ),

        // Ambient Glowing Orb 3 (Bottom Left)
        Positioned(
          bottom: -60,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF06B6D4).withAlpha(30) // Cyan
                  : const Color(0xFF38BDF8).withAlpha(25),
            ),
          ),
        ),

        // Full Screen Blur to diffuse the orbs into ultra-smooth ambient mesh
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: const SizedBox.expand(),
        ),

        // Foreground app content
        child,
      ],
    );
  }
}

