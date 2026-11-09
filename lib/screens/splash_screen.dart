import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'home_dashboard.dart';
import 'registration_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  bool _hasNavigated = false;
  Timer? _navigationTimer;

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse / Breathing Animation Controller (0.96 to 1.04)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseScaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // 3.5-Second Progress Controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });

    // Fallback Timer to guarantee transition at 3.5 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 3500), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();

    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) {
          return appState.isRegistered ? const HomeDashboard() : const RegistrationScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = Provider.of<AppState>(context).isTelugu;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0005),
      body: Stack(
        children: [
          // 1. Deep Midnight Ruby Backdrop Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A0005), // Midnight Crimson
                    Color(0xFF38000A), // Deep Ruby Maroon
                    Color(0xFF0B132B), // Deep Celestial Navy
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Ambient Glow Sphere - Top-Center Warm Golden Aura
          Positioned(
            top: size.height * 0.14,
            left: size.width * 0.5 - 120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // 3. Ambient Glow Sphere - Center-Bottom Glowing Crimson Flare
          Positioned(
            bottom: size.height * 0.18,
            left: size.width * 0.5 - 140,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD90429).withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD90429).withValues(alpha: 0.40),
                    blurRadius: 110,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // 4. Main Content Container with Glassmorphism Card
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Radiant Pulsing Center Emblem
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseScaleAnimation.value,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD90429), Color(0xFFFFD700)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withValues(
                                          alpha: 0.5 + (_pulseController.value * 0.2),
                                        ),
                                        blurRadius: 36 + (_pulseController.value * 12),
                                        spreadRadius: 6 + (_pulseController.value * 4),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFD90429).withValues(alpha: 0.4),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/app_icon.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 70,
                                            color: Color(0xFFFFD700),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),

                          // Primary Title: Bold Metallic Gold Lettering
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFF3B0), Color(0xFFFFD700)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              "YOUTH FOR CHRIST",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzel(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle: Frosted Gold Pill Container
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              "FELLOWSHIP",
                              style: GoogleFonts.cinzel(
                                color: const Color(0xFFFFD700),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tagline with Subtle Shimmer / Fade
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.82 + (_pulseController.value * 0.18),
                                child: Text(
                                  isTelugu
                                      ? "యువత కోసం క్రీస్తు ఫెలోషిప్ • వాక్య ధ్యానము"
                                      : "Living in His Light • Growing in His Word",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFF5F5F5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.6,
                                    height: 1.4,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. Bottom Ultra-Thin Golden Progress Indicator
          Positioned(
            bottom: 36,
            left: 44,
            right: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        minHeight: 2.5,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "INITIALIZING YFC FELLOWSHIP ENGINE...",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFD4AF37),
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
