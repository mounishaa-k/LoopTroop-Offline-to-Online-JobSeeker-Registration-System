import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_theme.dart';
import '../models/resume_record.dart';
import '../services/qr_service.dart';

class QrResultScreen extends StatelessWidget {
  final ResumeRecord record;

  const QrResultScreen({super.key, required this.record});

  String _buildQrData() {
    return QrService.encodeRecord(record);
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _buildQrData();
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Record Saved',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.highConfidence.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.highConfidence.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.highConfidence, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Record Saved Successfully',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(record.candidateName,
                            style: GoogleFonts.inter(
                                color: AppTheme.highConfidence, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 24),

            // Candidate summary
            _summaryCard(context),
            const SizedBox(height: 24),

            // QR Code
            Text('QR Code',
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 12),
            Text('Scan to retrieve candidate info',
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC), fontSize: 12)),
            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/records'),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('View All Records'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/capture', (r) => r.settings.name == '/home'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Register Another'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (_) => false),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final ext = record.extracted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, Icons.person_outline, 'Name', record.candidateName),
          if (record.primaryPhone.isNotEmpty)
            _row(context, Icons.phone_outlined, 'Phone', record.primaryPhone),
          if (record.primaryEmail.isNotEmpty)
            _row(context, Icons.email_outlined, 'Email', record.primaryEmail),
          if (ext.education.isNotEmpty)
            _row(
                context,
                Icons.school_outlined,
                'Education',
                '${ext.education.first.degree} ${ext.education.first.specialization}'
                    .trim()),
          if (ext.skills.isNotEmpty)
            _row(context, Icons.star_outline, 'Skills',
                ext.skills.take(4).join(', ')),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.mediumConfidence.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Status: PENDING SYNC',
                style: GoogleFonts.inter(
                    color: AppTheme.mediumConfidence,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
