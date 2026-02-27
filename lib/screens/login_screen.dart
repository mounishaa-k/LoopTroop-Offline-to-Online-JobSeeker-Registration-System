import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../constants.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await SupabaseService.signIn(_userCtrl.text.trim(), _passCtrl.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e
              .toString()
              .replaceAll('AuthException(message: ', '')
              .replaceAll('AuthApiException(message: ', '')
              .split(',')
              .first
              .replaceAll(RegExp(r'[()\]\[]'), '')
              .trim();

          // Capitalize first letter
          if (_errorMsg!.isNotEmpty) {
            _errorMsg = _errorMsg![0].toUpperCase() + _errorMsg!.substring(1);
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pitch black bg
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.badge_outlined,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConstants.appName,
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(AppConstants.appSubtitle,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF8899CC))),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 52),
                Text('Welcome back',
                        style: GoogleFonts.inter(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5))
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 6),
                Text('Sign in to access the job fair dashboard',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: const Color(0xFF8899CC)))
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 36),

                // Error
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lowConfidence.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.lowConfidence.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.lowConfidence, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: GoogleFonts.inter(
                                  color: AppTheme.lowConfidence, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email field
                TextFormField(
                  controller: _userCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: Color(0xFF8899CC)),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF8899CC)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF8899CC)),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter password' : null,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),
                const SizedBox(height: 28),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Sign In',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                const SizedBox(height: 20),

                // Register link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Don\'t have an account? ',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8899CC), fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Register',
                            style: GoogleFonts.inter(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700),
                          )
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
