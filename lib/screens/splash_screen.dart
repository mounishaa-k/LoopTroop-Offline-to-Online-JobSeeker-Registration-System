import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.badge_outlined,
                  color: Colors.white, size: 56),
            ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 1000.ms,
                curve: Curves.easeOutQuart),
            const SizedBox(height: 28),
            Text(
              AppConstants.appName,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 800.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
            const SizedBox(height: 8),
            Text(
              AppConstants.appSubtitle,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF8899CC),
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
            const SizedBox(height: 60),
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor.withValues(alpha: 0.7)),
              ),
            ).animate().fadeIn(delay: 1000.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
