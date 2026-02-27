import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../app_theme.dart';
import '../constants.dart';
import '../models/field_metadata.dart';
import '../models/resume_record.dart';
import '../models/extraction_result.dart';
import '../models/education_entry.dart';
import '../services/ocr_service.dart';
import '../services/ai_extraction_service.dart';
import '../services/supabase_service.dart';
import '../utils/platform_image.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  final List<XFile> _pages = [];
  bool _processing = false;
  String _statusMsg = '';

  // ── Image acquisition ─────────────────────────────────────────────────────

  Future<void> _captureFromCamera() async {
    if (kIsWeb) return; // should never be called on web (button disabled)
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (img != null && mounted) setState(() => _pages.add(img));
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _uploadFromGallery() async {
    try {
      final imgs = await _picker.pickMultiImage(imageQuality: 90);
      if (imgs.isNotEmpty && mounted) setState(() => _pages.addAll(imgs));
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  void _removePage(int index) => setState(() => _pages.removeAt(index));

  // ── OCR + extraction ──────────────────────────────────────────────────────

  Future<void> _processAndNavigate() async {
    if (_pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one image first')));
      return;
    }

    setState(() {
      _processing = true;
      _statusMsg = 'Extracting text from page 1…';
    });

    try {
      final rawTexts = <String>[];
      for (int i = 0; i < _pages.length; i++) {
        if (mounted) {
          setState(() => _statusMsg = 'Extracting text from page ${i + 1}…');
        }
        final text = await OcrService.recognizeText(_pages[i].path);
        rawTexts.add(text);
      }

      final fullText = rawTexts.join('\n\n');

      // ── AI + regex hybrid extraction ────────────────────────────────────────
      if (mounted) {
        setState(() => _statusMsg = AiExtractionService.isConfigured
            ? 'Analyzing with AI…'
            : 'Parsing fields…');
      }
      final ai = await AiExtractionService.extract(fullText);

      // Map Confidence enum → double
      double conf(Confidence c) => switch (c) {
            Confidence.high => 0.95,
            Confidence.medium => 0.65,
            Confidence.low => 0.40,
            Confidence.none => 0.0,
          };

      FieldMetadata fmeta(String v, Confidence c) => FieldMetadata(
            confidence: conf(c),
            sourcePage: 0,
            rawSnippet: v,
            extractionMethod: ai.fromAi ? 'gemini' : AppConstants.methodRegex,
          );

      final pagesTexts = rawTexts
          .asMap()
          .entries
          .map((e) => PageText(pageIndex: e.key, text: e.value))
          .toList();

      final extracted = ExtractionResult(
        fullName: ai.name.isNotEmpty
            ? FieldValue<String>(
                value: ai.name, metadata: fmeta(ai.name, ai.nameConf))
            : null,
        phones: ai.phone.isNotEmpty
            ? [
                ContactField(
                    value: ai.phone,
                    label: 'mobile',
                    metadata: fmeta(ai.phone, ai.phoneConf))
              ]
            : [],
        emails: ai.email.isNotEmpty
            ? [
                ContactField(
                    value: ai.email,
                    label: 'primary',
                    metadata: fmeta(ai.email, ai.emailConf))
              ]
            : [],
        education: ai.education.isNotEmpty
            ? [
                EducationEntry(
                    degree: ai.education,
                    institution: '',
                    pageIndex: 0,
                    metadata: fmeta(ai.education, ai.educationConf))
              ]
            : [],
        linkedinUrls: ai.linkedin.isNotEmpty
            ? [
                ContactField(
                    value: ai.linkedin,
                    label: 'linkedin',
                    metadata: fmeta(ai.linkedin, ai.linkedinConf))
              ]
            : [],
        skills: ai.skills,
        pagesTexts: pagesTexts,
      );

      final newDisplayId = await SupabaseService.getNextDisplayId();
      if (!mounted) return;

      final record = ResumeRecord(
        id: const Uuid().v4(),
        displayId: newDisplayId,
        rawText: rawTexts.join('\n\n---\n\n'),
        pagesTexts: pagesTexts,
        images: _pages.map((f) => f.path).toList(),
        extracted: extracted,
        extractionMetadata: {
          'extraction_version': AppConstants.extractionVersion,
          'ocr_engine': kIsWeb ? 'none_web' : 'google_mlkit',
          'extraction_method': ai.fromAi ? 'gemini_ai' : 'regex_fallback',
          'pages': _pages.length,
        },
      );

      if (mounted) Navigator.pushNamed(context, '/review', arguments: record);
    } on OcrException catch (e) {
      await _handleOcrFailure(e.message);
    } catch (e) {
      await _handleOcrFailure(e.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _handleOcrFailure(String detail) async {
    debugPrint('OCR error: $detail');
    if (!mounted) return;
    // Show snackbar then navigate to empty manual-entry form
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Could not extract data. Please enter manually.'),
      backgroundColor: AppTheme.mediumConfidence,
      duration: Duration(seconds: 4),
    ));

    final fallbackDisplayId = await SupabaseService.getNextDisplayId();
    if (!mounted) return;

    Navigator.pushNamed(context, '/review',
        arguments:
            ResumeRecord(id: const Uuid().v4(), displayId: fallbackDisplayId));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.lowConfidence));
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Scan Resume',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: _processing
          ? _buildProcessing()
          : Column(
              children: [
                if (kIsWeb) _buildWebBanner(),
                Expanded(
                    child: _pages.isEmpty ? _buildEmpty() : _buildPageList()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  /// Warning banner shown only on web.
  Widget _buildWebBanner() {
    return Container(
      width: double.infinity,
      color: AppTheme.mediumConfidence.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.phone_android,
              color: AppTheme.mediumConfidence, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For full functionality (camera & OCR), please run on a mobile device.',
              style: GoogleFonts.inter(
                  color: AppTheme.mediumConfidence, fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildProcessing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                  color: AppTheme.primaryColor, strokeWidth: 4),
            ).animate().fadeIn(),
            const SizedBox(height: 28),
            Text(_statusMsg,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('This may take a few seconds…',
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Icon(Icons.document_scanner_outlined,
                  color: AppTheme.primaryColor, size: 72),
            ).animate().fadeIn().scale(begin: const Offset(0.85, 0.85)),
            const SizedBox(height: 24),
            Text('Add Resume Pages',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Upload from gallery.\nFor camera & OCR, use the mobile app.'
                  : 'Capture with camera or upload from gallery.\nMultiple pages supported.',
              style: GoogleFonts.inter(
                  color: const Color(0xFF8899CC), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _BigActionBtn(
                    icon: Icons.camera_alt,
                    label: 'Capture from\nCamera',
                    color: AppTheme.primaryColor,
                    // Disabled on web — camera not supported
                    onTap: kIsWeb ? null : _captureFromCamera,
                    disabledMessage:
                        kIsWeb ? 'Camera not available on web' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BigActionBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Upload from\nGallery',
                    color: AppTheme.secondaryColor,
                    onTap: _uploadFromGallery,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text('${_pages.length} page(s) added',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF8899CC),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              if (!kIsWeb)
                _SmallBtn(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: _captureFromCamera),
              if (!kIsWeb) const SizedBox(width: 8),
              _SmallBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _uploadFromGallery),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _pages.length,
            onReorder: (from, to) {
              setState(() {
                if (to > from) to--;
                final item = _pages.removeAt(from);
                _pages.insert(to, item);
              });
            },
            itemBuilder: (ctx, i) => _PageTile(
              key: ValueKey(_pages[i].path),
              file: _pages[i],
              index: i,
              onDelete: () => _removePage(i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed:
                (_processing || _pages.isEmpty) ? null : _processAndNavigate,
            icon: const Icon(
              Icons.document_scanner_outlined,
              size: 20,
            ),
            label: Text(
              _pages.isEmpty
                  ? 'Add pages first'
                  : kIsWeb
                      ? 'Continue to Form (${_pages.length} image${_pages.length > 1 ? "s" : ""})'
                      : 'Run OCR & Extract (${_pages.length} page${_pages.length > 1 ? "s" : ""})',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _BigActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap; // null = disabled
  final String? disabledMessage;

  const _BigActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.disabledMessage,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Tooltip(
      message: disabled ? (disabledMessage ?? '') : '',
      child: GestureDetector(
        onTap: disabled
            ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(disabledMessage ??
                      'Camera not supported on web. Please use mobile device.'),
                  backgroundColor: AppTheme.mediumConfidence,
                ))
            : onTap,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: disabled ? color.withValues(alpha: 0.06) : color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
            ),
            child: Column(
              children: [
                Icon(icon,
                    color: disabled
                        ? color.withValues(alpha: 0.4)
                        : Colors.black87,
                    size: 32),
                const SizedBox(height: 12),
                Text(label,
                    style: GoogleFonts.inter(
                        color:
                            disabled ? const Color(0xFF556677) : Colors.black87,
                        fontSize: 14,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
                if (disabled) ...[
                  const SizedBox(height: 4),
                  Text('Web only',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF556677), fontSize: 10)),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.cardBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                    color: const Color(0xFFBBCCFF), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  final XFile file;
  final int index;
  final VoidCallback onDelete;
  const _PageTile(
      {required super.key,
      required this.file,
      required this.index,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          // ✅ Platform-safe: works on both web and mobile
          child: XFileImage(
            file: file,
            width: 52,
            height: 68,
            fit: BoxFit.cover,
          ),
        ),
        title: Text('Page ${index + 1}',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
        subtitle: Text(file.name,
            style:
                GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8899CC)),
            overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: Color(0xFF5566AA)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.lowConfidence),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
