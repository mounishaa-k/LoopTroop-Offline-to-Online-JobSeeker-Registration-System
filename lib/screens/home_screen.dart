import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../state/app_state.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('FairTrack',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.lowConfidence),
            tooltip: 'Sign out',
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Consumer<AppState>(
              builder: (_, state, __) => state.pendingCount > 0
                  ? Badge(
                      label: Text('${state.pendingCount}'),
                      child: const Icon(Icons.sync),
                    )
                  : const Icon(Icons.check_circle_outline,
                      color: AppTheme.highConfidence),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Job Fair Registration',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF908D8A), fontSize: 15)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.highConfidence,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Offline Mode Active',
                        style: GoogleFonts.inter(
                            color: const Color(0xFFCDC8C3),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    _ActionCard(
                      icon: Icons.document_scanner_outlined,
                      label: 'Quick Entry',
                      subtitle: 'Scan or capture a resume instantly',
                      color: AppTheme.primaryColor,
                      onTap: () => Navigator.pushNamed(context, '/capture'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _SmallActionCard(
                          icon: Icons.list_alt_outlined,
                          label: 'View\nSaved Data',
                          color: AppTheme.secondaryColor,
                          trailing: Consumer<AppState>(
                            builder: (_, state, __) => Text(
                              '${state.records.length}',
                              style: GoogleFonts.inter(
                                  color: Colors.black87,
                                  fontSize: 24,
                                  letterSpacing: -1,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          onTap: () => Navigator.pushNamed(context, '/records'),
                        ),
                        const SizedBox(width: 16),
                        _SmallActionCard(
                          icon: Icons.cloud_upload_outlined,
                          label: 'Sync\nData',
                          color: AppTheme.accentColor,
                          trailing: Consumer<AppState>(
                            builder: (_, state, __) => state.pendingCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${state.pendingCount} left',
                                      style: GoogleFonts.inter(
                                          color: Colors.black87,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  )
                                : const Icon(Icons.check,
                                    color: Colors.black54),
                          ),
                          onTap: () => Navigator.pushNamed(context, '/sync'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.black87, size: 28),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.black87, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 22,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        color: Colors.black87.withValues(alpha: 0.6),
                        fontSize: 13)),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget trailing;

  const _SmallActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.black87, size: 24),
                  ),
                  trailing,
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 18,
                          height: 1.2,
                          letterSpacing: -0.5,
                          fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.black87, size: 14),
                  ),
                ],
              )
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: 100.ms)
            .slideY(begin: 0.05, end: 0),
      ),
    );
  }
}
