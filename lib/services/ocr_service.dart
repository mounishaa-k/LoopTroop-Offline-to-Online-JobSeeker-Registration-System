import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Real on-device OCR using Google ML Kit (Android/iOS only).
class OcrService {
  static Future<String> recognizeText(String imagePath) async {
    if (kIsWeb) {
      throw OcrException(
          'OCR is not supported on web. Please run on a mobile device.');
    }
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(inputImage);
      final text = result.blocks
          .map((b) => b.lines.map((l) => l.text).join('\n'))
          .join('\n\n');
      return text.trim();
    } finally {
      recognizer.close();
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Parses structured fields from raw OCR text.
/// Rules: regex + keyword detection only. NEVER generates fake data.
/// Empty string means field was not found.
/// ─────────────────────────────────────────────────────────────────────────────
class ResumeTextParser {
  // ── Name ──────────────────────────────────────────────────────────────────

  /// First line near top that:
  ///   - contains only letters and spaces
  ///   - has 2–4 words
  ///   - does NOT contain digits, @, http, linkedin, github
  static String parseName(String text) {
    final lines = _lines(text);
    final skipRe = RegExp(
        r'[\d@]|http|www\.|linkedin|github|resume|curriculum|profile|'
        r'education|experience|skills|objective|summary|contact|address',
        caseSensitive: false);

    for (final line in lines.take(10)) {
      if (skipRe.hasMatch(line)) continue;
      // Only letters and spaces
      if (!RegExp(r'^[A-Za-z \.]+$').hasMatch(line)) continue;
      final words = line.trim().split(RegExp(r'\s+'));
      if (words.length >= 2 && words.length <= 4) return line.trim();
    }
    return '';
  }

  // ── Phone ─────────────────────────────────────────────────────────────────

  /// 10-digit Indian number, handles +91 / 0 prefix.
  static String parsePhone(String text) {
    // Normalize: remove formatting chars
    final normalized = text.replaceAll(RegExp(r'[ \-().]'), '');
    // +91 prefix
    final withPrefix = RegExp(r'\+91([6-9]\d{9})\b');
    final m1 = withPrefix.firstMatch(normalized);
    if (m1 != null) return m1.group(1)!;
    // 0 prefix
    final zeroPrefix = RegExp(r'\b0([6-9]\d{9})\b');
    final m2 = zeroPrefix.firstMatch(normalized);
    if (m2 != null) return m2.group(1)!;
    // Bare 10-digit starting with 6-9
    final bare = RegExp(r'\b([6-9]\d{9})\b');
    final m3 = bare.firstMatch(normalized);
    return m3?.group(1) ?? '';
  }

  // ── Email ─────────────────────────────────────────────────────────────────

  static String parseEmail(String text) =>
      RegExp(r'[\w.+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}')
          .firstMatch(text)
          ?.group(0)
          ?.toLowerCase() ??
      '';

  // ── LinkedIn ──────────────────────────────────────────────────────────────

  /// Extracts full linkedin.com/in/... URL or username.
  static String parseLinkedIn(String text) {
    // Full URL
    final urlRe = RegExp(r'(?:https?://)?(?:www\.)?linkedin\.com/in/([\w\-]+)',
        caseSensitive: false);
    final m = urlRe.firstMatch(text);
    if (m != null) return 'linkedin.com/in/${m.group(1)}';
    return '';
  }

  // ── Skills ────────────────────────────────────────────────────────────────

  /// Finds a skills section and extracts comma/line-separated values.
  static List<String> parseSkills(String text) {
    final lines = _lines(text);
    final headerRe = RegExp(
        r'^(skills?|technical\s+skills?|core\s+skills?|key\s+skills?'
        r'|competencies|technologies)',
        caseSensitive: false);

    var capture = false;
    final skills = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (headerRe.hasMatch(line.trim())) {
        capture = true;
        continue;
      }

      // Stop at next major section heading (ALL CAPS or common headings)
      if (capture && _isSectionHeading(line) && i > 0) break;

      if (capture) {
        // Could be comma-separated on one line
        if (line.contains(',')) {
          skills.addAll(line
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && s.length < 40));
        } else {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && trimmed.length < 40) {
            skills.add(trimmed);
          }
        }
        // Collect at most 5 lines of skills
        if (skills.length >= 20) break;
      }
    }

    return skills.toSet().toList(); // deduplicate
  }

  // ── Education ─────────────────────────────────────────────────────────────

  /// Returns the first line containing a degree/institution keyword.
  static String parseEducation(String text) {
    const kw = [
      'b.tech',
      'b.e.',
      'b.sc',
      'b.com',
      'b.a.',
      'bca',
      'b.ca',
      'mba',
      'm.tech',
      'm.sc',
      'm.com',
      'mca',
      'phd',
      'ph.d',
      'bachelor',
      'master',
      'diploma',
      'degree',
      'university',
      'college',
      'engineering',
      'science',
      'graduate',
    ];
    for (final line in _lines(text)) {
      final lower = line.toLowerCase();
      if (kw.any((k) => lower.contains(k))) return line.trim();
    }
    return '';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<String> _lines(String text) =>
      text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  static bool _isSectionHeading(String line) {
    if (line.toUpperCase() == line && line.length > 3) return true;
    final headings = RegExp(
        r'^(education|experience|work|employment|projects?|certif|'
        r'achievements?|awards?|hobbies|interests?|references?|languages?)',
        caseSensitive: false);
    return headings.hasMatch(line.trim());
  }
}

class OcrException implements Exception {
  final String message;
  OcrException(this.message);
  @override
  String toString() => message;
}
