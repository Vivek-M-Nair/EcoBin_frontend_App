import 'dart:async';
import 'package:flutter/material.dart';

class EcoBinSplashScreen extends StatefulWidget {
  /// The next page the app will transition to after the splash delay.
  final Widget nextScreen;

  const EcoBinSplashScreen({super.key, required this.nextScreen});

  @override
  State<EcoBinSplashScreen> createState() => _EcoBinSplashScreenState();
}

class _EcoBinSplashScreenState extends State<EcoBinSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup smooth logo scale and fade-in animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // 2. Automatically transition to the next page after 2.8 seconds
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                widget.nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // High-end premium cross-fade transition
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 650),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Premium Slate 950 background
      body: Stack(
        children: [
          // Ambient neon glow in the background center
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // We apply the blur inside a BoxShadow array to create the ambient glow
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.05),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Main Central Brand Column
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Emerald Icon Container
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF10B981),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Title (EcoBin)
                  RichText(
                    text: const TextSpan(
                      text: 'Eco',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Bin',
                          style: TextStyle(color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle / Tagline
                  const Text(
                    'A SMART WASTE MANAGEMENT SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B), // Slate 400
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Elegant Minimalist Loading Indicator at the bottom
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF10B981).withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
