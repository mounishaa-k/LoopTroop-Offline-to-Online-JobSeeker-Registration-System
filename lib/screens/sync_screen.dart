import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';
import '../state/app_state.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _done = false;
  int _synced = 0;
  int _failed = 0;
  List<String> _errors = [];

  Future<void> _startSync() async {
    final state = context.read<AppState>();
    if (state.pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending records to sync')));
      return;
    }
    try {
      final result = await state.syncAll();
      if (mounted) {
        setState(() {
          _done = true;
          _synced = result.synced;
          _failed = result.failed;
          _errors = result.errors;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _done = true;
          _failed = state.pendingCount;
          _errors = [e.toString()];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Sync Data',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Consumer<AppState>(
        builder: (_, state, __) {
          if (state.syncing) return _buildSyncing();
          if (_done) return _buildResult();
          return _buildReady(state.pendingCount);
        },
      ),
    );
  }

  Widget _buildReady(int pendingCount) {
    final configured = SupabaseService.isConfigured;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.4),
                    width: 2),
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: AppTheme.accentColor, size: 56),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 28),
            Text('Ready to Sync',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.mediumConfidence.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$pendingCount record(s) pending',
                  style: GoogleFonts.inter(
                      color: AppTheme.mediumConfidence,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            // Supabase config status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: configured
                        ? AppTheme.highConfidence.withValues(alpha: 0.4)
                        : AppTheme.mediumConfidence.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    configured
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    size: 16,
                    color: configured
                        ? AppTheme.highConfidence
                        : AppTheme.mediumConfidence,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    configured
                        ? 'Supabase Connected'
                        : 'Supabase not configured — using simulation',
                    style: GoogleFonts.inter(
                        color: configured
                            ? AppTheme.highConfidence
                            : AppTheme.mediumConfidence,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!configured)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Set kSupabaseUrl in supabase_service.dart',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF5566AA), fontSize: 11)),
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: pendingCount > 0 ? _startSync : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor),
                icon: const Icon(Icons.sync),
                label: Text(
                  configured ? 'Sync to Supabase' : 'Simulate Sync',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                  color: AppTheme.accentColor, strokeWidth: 5),
            ).animate().fadeIn(),
            const SizedBox(height: 28),
            Text('Uploading to Supabase…',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Please keep the app open',
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final allOk = _failed == 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allOk ? Icons.check_circle : Icons.warning_amber,
              color:
                  allOk ? AppTheme.highConfidence : AppTheme.mediumConfidence,
              size: 72,
            ).animate().scale().fadeIn(),
            const SizedBox(height: 20),
            Text(allOk ? 'Sync Complete!' : 'Sync Partially Done',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _statRow('Uploaded', '$_synced', AppTheme.highConfidence),
            if (_failed > 0)
              _statRow('Failed', '$_failed', AppTheme.lowConfidence),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                allOk
                    ? '✅ All records uploaded to Supabase and cleared locally.'
                    : '⚠️ $_synced uploaded. $_failed failed — please retry.',
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            // Show errors if any
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lowConfidence.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.lowConfidence.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Errors:',
                        style: GoogleFonts.inter(
                            color: AppTheme.lowConfidence,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ..._errors.take(3).map((e) => Text('• $e',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF8899CC), fontSize: 11))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (_) => false),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ',
              style: GoogleFonts.inter(
                  color: const Color(0xFF8899CC), fontSize: 14)),
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
