import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_theme.dart';
import '../models/resume_record.dart';
import '../services/qr_service.dart';
import '../utils/helpers.dart';

class RecordDetailScreen extends StatefulWidget {
  final ResumeRecord record;
  const RecordDetailScreen({super.key, required this.record});
  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late String _qrData;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _qrData = QrService.encodeRecord(widget.record);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(r.candidateName,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan a QR',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _QrScannerScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [Tab(text: 'Details'), Tab(text: 'QR Code')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildDetailsTab(r),
          _buildQrTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(ResumeRecord r) {
    final ext = r.extracted;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              _statusBadge(r),
              const SizedBox(width: 12),
              Text(r.displayId,
                  style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(Helpers.formatDateTime(r.createdAt),
                  style: GoogleFonts.inter(
                      color: const Color(0xFF8899CC), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),

          _infoSection('Identity', [
            if (ext.fullName != null)
              _row(Icons.person_outline, 'Full Name', ext.fullName!.value),
            if (ext.givenName != null)
              _row(Icons.badge_outlined, 'Given Name', ext.givenName!.value),
            if (ext.familyName != null)
              _row(Icons.badge_outlined, 'Family Name', ext.familyName!.value),
          ]),

          if (ext.phones.isNotEmpty ||
              ext.emails.isNotEmpty ||
              ext.address != null)
            _infoSection('Contact', [
              ...ext.phones.map((p) =>
                  _row(Icons.phone_outlined, 'Phone (${p.label})', p.value)),
              ...ext.emails.map((e) =>
                  _row(Icons.email_outlined, 'Email (${e.label})', e.value)),
              if (ext.address != null)
                _row(Icons.location_on_outlined, 'Address', ext.address!.value),
              ...ext.linkedinUrls
                  .map((l) => _row(Icons.link, 'LinkedIn', l.value)),
            ]),

          if (ext.education.isNotEmpty)
            _infoSection('Education', [
              ...ext.education.map((e) => _row(
                    Icons.school_outlined,
                    e.degree.isNotEmpty ? e.degree : 'Degree',
                    '${e.institution}${e.endYear.isNotEmpty ? " (${e.startYear}–${e.endYear})" : ""}${e.grade.isNotEmpty ? " | ${e.grade}" : ""}',
                  )),
            ]),

          if (ext.experience.isNotEmpty)
            _infoSection('Experience', [
              ...ext.experience.map((e) => _row(
                    Icons.work_outline,
                    e.title.isNotEmpty ? e.title : 'Role',
                    '${e.employer}${e.startDate.isNotEmpty ? " (${e.startDate}–${e.endDate})" : ""}',
                  )),
            ]),

          if (ext.skills.isNotEmpty)
            _infoSection('Skills', [_chips(ext.skills)]),

          if (ext.certifications.isNotEmpty)
            _infoSection('Certifications', [
              ...ext.certifications
                  .map((c) => _row(Icons.verified_outlined, '', c)),
            ]),

          if (ext.availability != null || ext.noticePeriod != null)
            _infoSection('Availability', [
              if (ext.availability != null)
                _row(Icons.event_available_outlined, 'Available',
                    ext.availability!.value),
              if (ext.noticePeriod != null)
                _row(Icons.timelapse_outlined, 'Notice',
                    ext.noticePeriod!.value),
            ]),
        ],
      ),
    );
  }

  Widget _statusBadge(ResumeRecord r) {
    final color =
        r.isPending ? AppTheme.mediumConfidence : AppTheme.highConfidence;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(r.status.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildQrTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Candidate QR Code',
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('Scan to retrieve candidate info',
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC), fontSize: 12)),
            Text('${_qrData.length} chars',
                style: GoogleFonts.inter(
                    color: const Color(0xFF5566AA), fontSize: 11)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _qrData));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Copied!')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Payload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(title.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1)),
        ),
        Container(
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
          child: Column(children: children),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 90,
              child: Text(label,
                  style: GoogleFonts.inter(
                      color: const Color(0xFF8899CC), fontSize: 12)),
            ),
          ],
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _chips(List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items
            .map((s) => Chip(
                  label: Text(s,
                      style:
                          GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ))
            .toList(),
      ),
    );
  }
}

// ── QR Scanner ────────────────────────────────────────────────────────────────

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();
  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null) {
        _scanned = true;
        _processResult(raw);
        break;
      }
    }
  }

  void _processResult(String raw) {
    if (!mounted) return;
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _QrResultSheet(rawData: raw),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan QR Code',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // Overlay guide
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Point at a FairTrack QR code',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrResultSheet extends StatelessWidget {
  final String rawData;
  const _QrResultSheet({required this.rawData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text('Scanned Candidate',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Text(
              rawData,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
