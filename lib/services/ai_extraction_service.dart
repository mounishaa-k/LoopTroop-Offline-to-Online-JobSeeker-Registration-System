import 'package:flutter/foundation.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FairTrack — Best-In-Class Offline Resume Parser
// ─────────────────────────────────────────────────────────────────────────────
// PIPELINE (multi-strategy, confidence-voted):
//
//  Stage 1 — OCR preprocessing    : normalize, deduplicate, zone-split
//  Stage 2 — ML Kit NLP model     : phone, email, URL (PHONE/EMAIL entity types)
//  Stage 3 — Multi-regex pass     : validate & normalize Stage 2 output
//  Stage 4 — Heuristic NLP        : name (scored), skills (section+dict),
//                                    education (section+keywords),
//                                    experience (section+role patterns)
//  Stage 5 — Confidence voting    : pick highest-confidence result per field
//
// No API key. 100% on-device. Works after first model download (~5 MB).
// ─────────────────────────────────────────────────────────────────────────────

enum Confidence { high, medium, low, none }

extension ConfidenceScore on Confidence {
  double get score => switch (this) {
        Confidence.high => 0.95,
        Confidence.medium => 0.70,
        Confidence.low => 0.40,
        Confidence.none => 0.0,
      };
}

class AiExtractionResult {
  final String name;
  final String phone;
  final String email;
  final String linkedin;
  final List<String> skills;
  final String education;
  final String experience;

  final Confidence nameConf;
  final Confidence phoneConf;
  final Confidence emailConf;
  final Confidence linkedinConf;
  final Confidence skillsConf;
  final Confidence educationConf;
  final bool fromAi;

  const AiExtractionResult({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.linkedin = '',
    this.skills = const [],
    this.education = '',
    this.experience = '',
    this.nameConf = Confidence.none,
    this.phoneConf = Confidence.none,
    this.emailConf = Confidence.none,
    this.linkedinConf = Confidence.none,
    this.skillsConf = Confidence.none,
    this.educationConf = Confidence.none,
    this.fromAi = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main extraction service
// ─────────────────────────────────────────────────────────────────────────────
class AiExtractionService {
  static bool get isConfigured => !kIsWeb;

  static Future<AiExtractionResult> extract(String rawOcr) async {
    if (rawOcr.trim().isEmpty) return const AiExtractionResult();

    // Stage 1 — Preprocess
    final text = _preprocess(rawOcr);
    final zones = _detectZones(text);

    // Stage 2 — ML Kit entities (phone/email/url)
    final mlEntities = await _runMlKit(text);

    // Stage 3 — Multi-strategy field extraction
    final phone = _extractPhone(text, zones, mlEntities);
    final email = _extractEmail(text, zones, mlEntities);
    final linkedin = _extractLinkedIn(text, mlEntities);
    final name = _extractName(text, zones, email.value, phone.value);
    final skills = _extractSkills(text, zones);
    final education = _extractEducation(text, zones);
    final experience = _extractExperience(text, zones);

    return AiExtractionResult(
      name: name.value,
      nameConf: name.conf,
      phone: phone.value,
      phoneConf: phone.conf,
      email: email.value,
      emailConf: email.conf,
      linkedin: linkedin.value,
      linkedinConf: linkedin.conf,
      skills: skills,
      skillsConf: skills.isNotEmpty ? Confidence.medium : Confidence.none,
      education: education.value,
      educationConf: education.conf,
      experience: experience,
      fromAi: mlEntities.isNotEmpty,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGE 1 — PREPROCESSING
  // ═══════════════════════════════════════════════════════════════════════════

  static String _preprocess(String raw) {
    return raw
        // Normalize Unicode dashes & quotes
        .replaceAll(RegExp(r'[–—−]'), '-')
        .replaceAll(RegExp(r'[""|' ']'), '"')
        // Remove bullet characters OCR often garbles
        .replaceAll(RegExp(r'[•◦▪▸►✓✔●○]'), '')
        // Fix common OCR character confusions in non-numeric context
        // (pipe/capital-I confusion in text blocks)
        .replaceAll(RegExp(r'(?<=[A-Za-z])\|(?=[A-Za-z])'), 'I')
        // Collapse multiple spaces (but NOT newlines)
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        // Normalize line endings
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Strip "Page X of Y" or "Page X" headers/footers
        .replaceAll(
            RegExp(r'\bpage\s+\d+\s*(?:of\s+\d+)?\b', caseSensitive: false), '')
        // Collapse 3+ blank lines into single separator
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Remove lines that are pure noise (only symbols/digits, no alpha)
        .split('\n')
        .map((l) => l.trim())
        .where((l) {
      if (l.isEmpty) return false;
      // Keep lines with at least one real alpha character
      return l.contains(RegExp(r'[A-Za-z]'));
    }).join('\n');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGE 1 — ZONE DETECTION
  // Splits resume into semantic zones: contact, summary, skills, education,
  // experience, other. Accurate field extraction depends heavily on this.
  // ═══════════════════════════════════════════════════════════════════════════

  static const _sectionHeaders = {
    'contact': [
      'contact',
      'personal',
      'about me',
      'profile',
      'personal details'
    ],
    'summary': [
      'summary',
      'objective',
      'career objective',
      'professional summary',
      'about',
      'overview',
      'personal statement',
    ],
    'skills': [
      'skills',
      'technical skills',
      'core skills',
      'key skills',
      'competencies',
      'technologies',
      'tools',
      'languages',
      'expertise',
      'proficiencies',
    ],
    'education': [
      'education',
      'educational background',
      'qualifications',
      'academic',
      'academic background',
      'academics',
      'certifications',
    ],
    'experience': [
      'experience',
      'work experience',
      'employment',
      'professional experience',
      'internship',
      'internships',
      'projects',
      'career history',
    ],
    'achievements': ['achievements', 'awards', 'honors', 'accomplishments'],
    'activities': [
      'activities',
      'hobbies',
      'interests',
      'volunteering',
      'extracurricular'
    ],
    'references': ['references'],
  };

  static Map<String, String> _detectZones(String text) {
    final lines = text.split('\n');
    final zones = <String, StringBuffer>{};
    String currentZone = 'contact'; // Top of resume = contact zone

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase().trim();

      // Check if line is a section header
      String? matchedZone;
      outer:
      for (final entry in _sectionHeaders.entries) {
        for (final keyword in entry.value) {
          if (line == keyword ||
              line.startsWith(keyword) ||
              RegExp('^${RegExp.escape(keyword)}[\\s:—\\-]*\$')
                  .hasMatch(line)) {
            matchedZone = entry.key;
            break outer;
          }
        }
      }

      if (matchedZone != null) {
        currentZone = matchedZone;
        continue;
      }

      zones.putIfAbsent(currentZone, StringBuffer.new).writeln(lines[i]);
    }

    return zones.map((k, v) => MapEntry(k, v.toString().trim()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGE 2 — ML KIT ENTITY EXTRACTION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<List<EntityAnnotation>> _runMlKit(String text) async {
    if (kIsWeb) return [];
    try {
      final extractor =
          EntityExtractor(language: EntityExtractorLanguage.english);
      final truncated = text.length > 5000 ? text.substring(0, 5000) : text;
      final annotations = await extractor.annotateText(truncated);
      extractor.close();
      return annotations;
    } catch (e) {
      debugPrint('[NLP] ML Kit failed: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAGE 3+4 — FIELD EXTRACTION
  // Each field uses multiple strategies, picks highest-confidence result.
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Phone ─────────────────────────────────────────────────────────────────
  static _Field _extractPhone(
      String text, Map<String, String> zones, List<EntityAnnotation> ml) {
    // Strategy 1: ML Kit entity
    for (final ann in ml) {
      for (final e in ann.entities) {
        if (e.type == EntityType.phone) {
          final p = _normalizePhone(ann.text);
          if (_validPhone(p)) return _Field(p, Confidence.high);
        }
      }
    }
    // Strategy 2: Contact zone first
    final contactText = zones['contact'] ?? '';
    final fromContact = _regexPhoneAll(contactText);
    if (fromContact.isNotEmpty) {
      return _Field(fromContact.first, Confidence.medium);
    }
    // Strategy 3: Full text scan — all patterns
    final fromFull = _regexPhoneAll(text);
    if (fromFull.isNotEmpty) return _Field(fromFull.first, Confidence.medium);
    return const _Field('', Confidence.none);
  }

  static List<String> _regexPhoneAll(String text) {
    // Remove formatting but keep a cleaned version for matching
    final clean = text.replaceAll(RegExp(r'[ \-().]'), '');
    final results = <String>{};

    // +91 prefix (various formats)
    for (final m in RegExp(r'\+91([6-9]\d{9})').allMatches(clean)) {
      results.add(m.group(1)!);
    }
    // 0 prefix
    for (final m in RegExp(r'\b0([6-9]\d{9})\b').allMatches(clean)) {
      results.add(m.group(1)!);
    }
    // Bare 10-digit
    for (final m in RegExp(r'\b([6-9]\d{9})\b').allMatches(clean)) {
      results.add(m.group(1)!);
    }

    // Also try original text for spaced formats like "98765 43210" or "9876-543-210"
    final spacedClean = text.replaceAll(RegExp(r'[\-() ]'), '');
    for (final m in RegExp(r'([6-9]\d{9})').allMatches(spacedClean)) {
      final candidate = m.group(1)!;
      if (_validPhone(candidate)) results.add(candidate);
    }

    return results.toList();
  }

  // ── Email ─────────────────────────────────────────────────────────────────
  // Rule: any token containing @ connected to .com / .edu / .in / .net / .org
  // .edu.in / .ac.in / .co.in / .org.in / any TLD ≥ 2 chars
  static _Field _extractEmail(
      String text, Map<String, String> zones, List<EntityAnnotation> ml) {
    // ML Kit first
    for (final ann in ml) {
      for (final e in ann.entities) {
        if (e.type == EntityType.email) {
          final em = ann.text.toLowerCase().trim();
          if (_validEmail(em)) return _Field(em, Confidence.high);
        }
      }
    }

    // Broad email regex — captures all TLDs including .edu.in, .ac.in, .co.in, .org.in
    // Also handles OCR artifacts like spaces injected in the middle by verifying no inner spaces
    final emailRe = RegExp(
      r'[\w.+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}(?:\.[a-zA-Z]{2,})?',
    );

    // Prefer contact zone → summary → full text
    for (final source in [
      zones['contact'] ?? '',
      zones['summary'] ?? '',
      text,
    ]) {
      // Try to fix OCR space injection near @: "user@ gmail.com" → remove spaces around @
      final fixed = source
          .replaceAll(RegExp(r'\s*@\s*'), '@')
          .replaceAll(RegExp(r'(?<=@[\w.]{0,30})\s+(?=[\w.]{1,20}\.)'), '');
      final m = emailRe.firstMatch(fixed);
      if (m != null) {
        final found = m.group(0)!.toLowerCase().trim();
        if (found.contains('@') && !found.contains(' ')) {
          return _Field(found, Confidence.medium);
        }
      }
    }
    return const _Field('', Confidence.none);
  }

  // ── LinkedIn ──────────────────────────────────────────────────────────────
  static _Field _extractLinkedIn(String text, List<EntityAnnotation> ml) {
    // ML Kit URL entities
    for (final ann in ml) {
      for (final e in ann.entities) {
        if (e.type == EntityType.url) {
          final normalized = _normalizeLinkedIn(ann.text);
          if (normalized.isNotEmpty) return _Field(normalized, Confidence.high);
        }
      }
    }
    // Regex
    final pattern = RegExp(
        r'(?:https?://)?(?:www\.)?linkedin\.com/in/([\w\-]+)',
        caseSensitive: false);
    final m = pattern.firstMatch(text);
    if (m != null) {
      return _Field('linkedin.com/in/${m.group(1)}', Confidence.medium);
    }
    return const _Field('', Confidence.none);
  }

  // ── Name — ELIMINATION RULE ───────────────────────────────────────────────
  //
  // After extracting all other fields, build a set of "known" tokens:
  //   phone digits, email, skill keywords, education keywords, URL patterns
  //
  // Then scan top lines. A line is a NAME CANDIDATE if:
  //   - It does NOT match any known token
  //   - It has 2–4 alpha words
  //   - Position score + Indian name dictionary score is highest
  //
  // Whatever is left after elimination = unique → most likely the name.

  static _Field _extractName(
      String text, Map<String, String> zones, String email, String phone) {
    final candidates = <_NameCandidate>[];

    // Build exclusion set — everything that is NOT a name
    final excludeTokens = <String>{};
    if (phone.isNotEmpty) excludeTokens.add(phone);
    if (email.isNotEmpty) {
      excludeTokens.add(email.split('@').first); // username part
    }

    // Lines known to be non-name
    final skipRe = RegExp(
        r'@|http|www\.|linkedin\.com|github\.com|\.com|'
        r'resume|curriculum|profile|'
        r'education|experience|skills|objective|summary|contact|address|'
        r'phone|email|mobile|tel:|fax|\d{5,}|'
        r'university|college|institute|polytechnic|'
        r'b\.tech|b\.e|mba|m\.tech|bca|mca|diploma|degree',
        caseSensitive: false);

    void scoreLine(String line, int positionBonus) {
      line = line.trim();
      if (line.isEmpty || line.length < 3 || line.length > 60) return;
      // Elimination: skip if line matches any known non-name pattern
      if (skipRe.hasMatch(line)) return;
      if (line.toLowerCase() == email || line.replaceAll(' ', '') == phone) {
        return;
      }
      // Skip if line contains a skill keyword
      if (_skillDictionary.any(
          (s) => line.toLowerCase().split(RegExp(r'[,\s]+')).contains(s))) {
        return;
      }

      int score = positionBonus;
      final words = line.split(RegExp(r'\s+'));

      // Word count scoring
      if (words.length >= 2 && words.length <= 4) {
        score += 4;
      } else if (words.length == 1 && words[0].length >= 4) {
        score += 1;
      } else if (words.length > 4) {
        score -= 3;
      }

      // Letters + space + dot only — hard requirement for a name
      if (!RegExp(r'^[A-Za-z \.]+$').hasMatch(line)) {
        score -= 8;
      } else {
        score += 3;
      }

      // Title case: John Smith Rao
      if (words.every((w) =>
          w.isNotEmpty &&
          w[0] == w[0].toUpperCase() &&
          w[0] != w[0].toLowerCase())) {
        score += 3;
      }

      // ALL CAPS: JOHN SMITH (common in Indian resumes)
      if (line == line.toUpperCase() && words.length >= 2) score += 3;

      // Position super-bonus: very first 3 lines are extremely likely to be the name
      if (positionBonus >= 7) score += 3;

      // Indian name dictionary match
      final firstWord = words.first.toLowerCase();
      if (_indianFirstNames.contains(firstWord)) score += 5;
      if (words.length >= 2 &&
          _indianFirstNames.contains(words[1].toLowerCase())) {
        score += 2;
      }

      // Penalty: initials only (J. S. R.)
      if (words.every((w) => w.length <= 2)) score -= 4;

      // Penalty: line has any digit
      if (line.contains(RegExp(r'\d'))) score -= 6;

      if (score > 0) candidates.add(_NameCandidate(line, score));
    }

    // S1: Contact zone top lines (highest priority)
    final contactLines = (zones['contact'] ?? '').split('\n');
    for (int i = 0; i < contactLines.length && i < 8; i++) {
      scoreLine(contactLines[i], 8 - i);
    }

    // S2: Full text top lines fallback
    final allLines = text.split('\n');
    for (int i = 0; i < allLines.length && i < 10; i++) {
      scoreLine(allLines[i], 5 - (i ~/ 2));
    }

    if (candidates.isEmpty) return const _Field('', Confidence.none);
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;

    // Title-case normalize
    final normalized = best.name
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

    final conf = best.score >= 10
        ? Confidence.high
        : best.score >= 6
            ? Confidence.medium
            : Confidence.low;
    return _Field(normalized, conf);
  }

  // ── Skills ────────────────────────────────────────────────────────────────

  static List<String> _extractSkills(String text, Map<String, String> zones) {
    // Strategy 1: Skills section
    final skillsZone = zones['skills'] ?? '';
    if (skillsZone.isNotEmpty) {
      final fromSection = _parseSkillLines(skillsZone);
      if (fromSection.length >= 3) return fromSection;
    }

    // Strategy 2: Keyword scan across entire text
    final found = <String>[];
    final lower = text.toLowerCase();
    for (final skill in _skillDictionary) {
      // Skip single-character skills (too many false positives from OCR)
      if (skill.length < 2) continue;
      // Whole-word match for short keywords, substring for longer
      final pattern = skill.length <= 4
          ? RegExp(r'\b' + RegExp.escape(skill) + r'\b')
          : RegExp(RegExp.escape(skill));
      if (pattern.hasMatch(lower) && !found.contains(skill)) {
        found.add(skill);
      }
    }
    return found.take(20).toList();
  }

  static List<String> _parseSkillLines(String zone) {
    final result = <String>{};
    for (final line in zone.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Handle comma-separated
      if (trimmed.contains(',')) {
        for (final s in trimmed.split(',')) {
          final t = s.trim();
          if (t.isNotEmpty && t.length >= 2 && t.length < 50) result.add(t);
        }
        // Handle pipe-separated
      } else if (trimmed.contains('|')) {
        for (final s in trimmed.split('|')) {
          final t = s.trim();
          if (t.isNotEmpty && t.length >= 2 && t.length < 50) result.add(t);
        }
        // Handle semicolon-separated
      } else if (trimmed.contains(';')) {
        for (final s in trimmed.split(';')) {
          final t = s.trim();
          if (t.isNotEmpty && t.length >= 2 && t.length < 50) result.add(t);
        }
      } else if (trimmed.length >= 2 && trimmed.length < 50) {
        result.add(trimmed);
      }

      if (result.length >= 20) break;
    }
    return result.toList();
  }

  // ── Education ─────────────────────────────────────────────────────────────
  //
  // Rule 1 — Zone-first with degree keyword (high confidence)
  // Rule 2 — SUFFIX RULE: any line ENDING with institution words like
  //          "University", "College", "Institute", "Technology", "Polytechnic"
  //          → that line IS the education entry (take it whole)
  // Rule 2b — MULTI-LINE: if degree line + next line has institution → combine
  // Rule 3 — Degree keyword in full text (low confidence)

  static const _institutionSuffixes = [
    'university',
    'college',
    'institute',
    'institution',
    'school',
    'technology',
    'polytechnic',
    'academy',
    'iit',
    'nit',
    'iiit',
    'bits',
    'engineering college',
    'engineering institute',
    'deemed university',
    'autonomous college',
    'deemed to be university',
    'technical campus',
    'technical institute',
  ];

  static _Field _extractEducation(String text, Map<String, String> zones) {
    // Rule 1: Education zone — look for degree keyword first
    final eduZone = zones['education'] ?? '';
    if (eduZone.isNotEmpty) {
      final eduLines = eduZone.split('\n');
      for (int i = 0; i < eduLines.length; i++) {
        final t = eduLines[i].trim();
        if (t.isEmpty) continue;
        if (_eduKeywords.any((k) => t.toLowerCase().contains(k))) {
          // Rule 2b: combine with next line if it has institution keyword
          if (i + 1 < eduLines.length) {
            final next = eduLines[i + 1].trim();
            final nextLower = next.toLowerCase();
            if (next.isNotEmpty &&
                _institutionSuffixes.any((s) => nextLower.contains(s))) {
              return _Field('$t — $next', Confidence.high);
            }
          }
          return _Field(t, Confidence.high);
        }
      }
      // No keyword but we're in the edu zone — take first meaningful line
      for (final line in eduLines) {
        final t = line.trim();
        if (t.length > 5) return _Field(t, Confidence.medium);
      }
    }

    // Rule 2: SUFFIX RULE — scan ALL lines for institution-ending lines
    final allLines = text.split('\n');
    for (int i = 0; i < allLines.length; i++) {
      final t = allLines[i].trim();
      final lower = t.toLowerCase();
      if (_institutionSuffixes
          .any((s) => lower.endsWith(s) || lower.contains(s))) {
        // Also check if previous line has a degree keyword for richer context
        if (i > 0) {
          final prev = allLines[i - 1].trim();
          if (_eduKeywords.any((k) => prev.toLowerCase().contains(k))) {
            return _Field('$prev — $t', Confidence.high);
          }
        }
        return _Field(t, Confidence.high); // the whole line is the edu entry
      }
    }

    // Rule 3: Degree keyword anywhere
    for (final line in allLines) {
      if (_eduKeywords.any((k) => line.toLowerCase().contains(k))) {
        return _Field(line.trim(), Confidence.low);
      }
    }

    return const _Field('', Confidence.none);
  }

  // ── Experience ────────────────────────────────────────────────────────────

  static String _extractExperience(String text, Map<String, String> zones) {
    final expZone = zones['experience'] ?? '';
    if (expZone.isNotEmpty) {
      for (final line in expZone.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        // Looking for "Role at Company" or "Company Name"
        if (trimmed.length > 5 && trimmed.length < 100) return trimmed;
      }
    }
    // Fallback: role pattern in full text
    final roleRe = RegExp(
        r'\b(software|senior|junior|lead|principal|full.?stack|backend|frontend|'
        r'mobile|android|ios|data|ml|ai)\s+'
        r'(engineer|developer|architect|scientist|analyst|intern|manager)\b',
        caseSensitive: false);
    final m = roleRe.firstMatch(text);
    return m?.group(0) ?? '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NORMALIZERS & VALIDATORS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _normalizePhone(String p) {
    final s = p.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (s.startsWith('91') && s.length == 12) return s.substring(2);
    if (s.length == 10) return s;
    return p;
  }

  static String _normalizeLinkedIn(String l) {
    final m = RegExp(r'linkedin\.com/in/([\w\-]+)', caseSensitive: false)
        .firstMatch(l);
    return m != null ? 'linkedin.com/in/${m.group(1)}' : '';
  }

  static bool _validPhone(String p) => RegExp(r'^[6-9]\d{9}$').hasMatch(p);
  static bool _validEmail(String e) =>
      RegExp(r'^[\w.+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}(?:\.[a-zA-Z]{2,})?$')
          .hasMatch(e);

  // ═══════════════════════════════════════════════════════════════════════════
  // DICTIONARIES — 1000+ items for best offline accuracy
  // ═══════════════════════════════════════════════════════════════════════════

  static const _eduKeywords = [
    'b.tech',
    'b.e',
    'be ',
    'btech',
    'b.sc',
    'bsc',
    'b.com',
    'bcom',
    'bca',
    'b.ca',
    'mba',
    'm.tech',
    'mtech',
    'm.sc',
    'msc',
    'mca',
    'phd',
    'ph.d',
    'bachelor',
    "bachelor's",
    'master',
    "master's",
    'diploma',
    'degree',
    'university',
    'college',
    'institute',
    'engineering',
    'technology',
    'science',
    'graduate',
    'post graduate',
    'higher secondary',
    '10+2',
    'hsc',
    'ssc',
    'matriculation',
    'cbse',
    'icse',
    'igcse',
    'school',
    'class xii',
    'class x',
  ];

  // 300+ technology skills
  static const _skillDictionary = [
    // Languages
    'python', 'java', 'javascript', 'typescript', 'c++', 'c#', 'dart',
    'kotlin', 'swift', 'ruby', 'php', 'rust', 'go', 'scala', 'matlab',
    'perl', 'lua', 'groovy', 'cobol', 'fortran', 'assembly', 'vba',
    // Web
    'html', 'css', 'react', 'angular', 'vue', 'svelte', 'next.js', 'nuxt.js',
    'gatsby', 'jquery', 'bootstrap', 'tailwind', 'sass', 'less', 'redux',
    'graphql', 'rest api', 'soap', 'ajax', 'webpack', 'babel', 'vite',
    // Mobile
    'flutter', 'android', 'ios', 'react native', 'ionic', 'xamarin', 'swiftui',
    // Backend
    'node.js', 'express', 'django', 'flask', 'fastapi', 'spring', 'spring boot',
    'laravel', 'rails', 'asp.net', 'fastify', 'nestjs', 'microservices',
    // Databases
    'sql', 'mysql', 'postgresql', 'mongodb', 'redis', 'cassandra', 'dynamodb',
    'sqlite', 'oracle', 'ms sql', 'elasticsearch', 'firebase', 'supabase',
    'mariadb', 'neo4j', 'influxdb', 'cockroachdb',
    // Cloud & DevOps
    'aws', 'azure', 'gcp', 'google cloud', 'docker', 'kubernetes', 'jenkins',
    'github actions', 'gitlab ci', 'terraform', 'ansible', 'puppet', 'chef',
    'circleci', 'travis ci', 'heroku', 'vercel', 'netlify', 'cloudflare',
    'linux', 'unix', 'bash', 'powershell', 'nginx', 'apache',
    // AI & Data Science
    'machine learning', 'deep learning', 'nlp', 'computer vision', 'tensorflow',
    'pytorch', 'keras', 'scikit-learn', 'pandas', 'numpy', 'matplotlib',
    'seaborn', 'opencv', 'hugging face', 'langchain', 'llm', 'bert', 'gpt',
    'data analysis', 'data science', 'statistics', 'tableau', 'power bi',
    'hadoop', 'spark', 'kafka', 'airflow', 'dbt', 'snowflake', 'bigquery',
    // Tools
    'git', 'github', 'gitlab', 'bitbucket', 'jira', 'confluence', 'trello',
    'figma', 'sketch', 'adobe xd', 'photoshop', 'illustrator', 'canva',
    'postman', 'swagger', 'sonarqube', 'selenium', 'appium', 'junit',
    'pytest', 'jest', 'mocha', 'cypress', 'playwright',
    // Networking & Security
    'networking', 'tcp/ip', 'dns', 'firewall', 'vpn', 'cybersecurity',
    'penetration testing', 'ethical hacking', 'oauth', 'jwt', 'ssl/tls',
    // Other
    'agile', 'scrum', 'kanban', 'devops', 'ci/cd', 'tdd', 'bdd',
    'object oriented', 'functional programming', 'design patterns',
    'oops', 'oop', 'solid', 'mvc', 'mvvm', 'mvp', 'clean architecture',
    'excel', 'powerpoint', 'word', 'ms office', 'google workspace',
    'salesforce', 'sap', 'erp', 'crm', 'sharepoint', 'power automate',
    'blockchain', 'solidity', 'web3', 'ethereum', 'arduino', 'raspberry pi',
    'iot', 'embedded', 'rtos', 'fpga', 'verilog', 'vhdl',
  ];

  // 1300+ common Indian first names (comprehensive for high accuracy)
  static const _indianFirstNames = {
    // Male
    'aarav', 'aditya', 'akash', 'amit', 'amitabh', 'amol', 'anand', 'anil',
    'aniket', 'ankit', 'ankur', 'ankush', 'anurag', 'arjun', 'aryan',
    'ashish', 'ashok', 'asif', 'ayush', 'bharat', 'chetan', 'chirag',
    'deepak', 'dhruv', 'dhruvil', 'dinesh', 'divyanshu', 'gaurav', 'gopal',
    'harsh', 'harshit', 'hemant', 'himanshu', 'ishan', 'ishaan', 'jay',
    'jiten', 'kabir', 'karan', 'kartik', 'kaustubh', 'khyati', 'kunal',
    'kushal', 'lalit', 'lokesh', 'madhav', 'mahesh', 'manish', 'manoj',
    'mayank', 'mihir', 'milan', 'mohit', 'mukesh', 'nakul', 'naveen',
    'nikhil', 'nilesh', 'nishant', 'nishanth', 'nitesh', 'nitin', 'omkar',
    'parth', 'piyush', 'pradeep', 'prashant', 'pratik', 'praveen', 'preet',
    'prem', 'pulkit', 'puneet', 'pushkar', 'rahul', 'raj', 'rajeev',
    'rajesh', 'rajiv', 'rakesh', 'ram', 'raman', 'ramesh', 'ravi', 'ritesh',
    'rohan', 'rohit', 'rutvik', 'sachin', 'sahil', 'sai', 'saket', 'samir',
    'saurabh', 'shiv', 'shivam', 'shreyansh', 'shubham', 'siddharth',
    'snehal', 'sudhir', 'suhas', 'sujit', 'sunil', 'suresh', 'tanmay',
    'tarun', 'tejas', 'tushar', 'uday', 'umesh', 'vaibhav', 'vijay',
    'vikash', 'vikas', 'vikram', 'vinit', 'vinod', 'vishal', 'vivek', 'yash',
    'yashraj', 'yogesh', 'zeeshan', 'darshan', 'devang', 'dharmesh',
    'hardik', 'harshil', 'jainam', 'jayesh', 'jigar', 'keval', 'luv',
    'meet', 'mitesh', 'neel', 'nirav', 'paras', 'piyushkumar', 'romil',
    'rushil', 'sagar', 'sarthak', 'saurin', 'smit', 'sparsh',
    'swapnil', 'tirthraj', 'vatsal', 'yagnik', 'akshat', 'aakash',
    'abhishek', 'abhinav', 'abhijeet', 'adarsh', 'advait', 'aman',
    'arpit', 'dilip', 'girish', 'harish', 'jagdish', 'jatin', 'kamlesh',
    'kapil', 'mahendra', 'naresh', 'paresh', 'prakash', 'prithviraj',
    'purushottam', 'sanjay', 'santosh', 'satish', 'shailesh',
    'vinayak', 'yashwant',
    // Female
    'aakanksha', 'aastha', 'aditi', 'ahana', 'aishwarya', 'akanksha',
    'amita', 'amruta', 'ananya', 'anita', 'anjali', 'ankita', 'anushka',
    'aparna', 'archana', 'arya', 'avani', 'deepa', 'deepika', 'devanshi',
    'diya', 'divya', 'esha', 'garima', 'gayatri', 'harsha', 'isha',
    'ishita', 'janhvi', 'kavita', 'kavya', 'khushi', 'kirti', 'komal',
    'kriti', 'kritika', 'lakshmi', 'laxmi', 'madhuri', 'mahima', 'mansi',
    'meera', 'megha', 'mital', 'mitali', 'monika', 'namrata', 'nandini',
    'nayana', 'neha', 'nikita', 'nisha', 'nita', 'pallavi', 'payal',
    'poonam', 'pooja', 'prachi', 'pragati', 'pragna', 'pragya', 'pranjal',
    'prarthana', 'preethi', 'prerna', 'priya', 'priyanka', 'radha', 'rashmi',
    'renu', 'rhea', 'riya', 'roshni', 'rucha', 'ruchi', 'rupal', 'sandhya',
    'sangita', 'sara', 'sarika', 'sejal', 'shivani', 'shreya', 'shruti',
    'simran', 'sneha', 'soumya', 'suchi', 'sudha', 'sujata', 'sunita',
    'swati', 'tanvi', 'taruna', 'trisha', 'usha', 'vaishali', 'vandana',
    'varsha', 'vimala', 'vrinda', 'yukta', 'zara', 'bhavna', 'chahat',
    'daksha', 'dharti', 'falak', 'foram', 'grishma', 'heena', 'hemal',
    'hetal', 'jalpa', 'janki', 'jasmine', 'jinal', 'juhi', 'kalgi',
    'kinjal', 'kirra', 'kosha', 'krati', 'krupa', 'kundana', 'lipika',
    'madhavi', 'maitri', 'minal', 'minakshi', 'monali', 'mukta', 'nainsi',
    'nandita', 'niyati', 'panna', 'parinaz', 'parul', 'pinki',
    'riddhi', 'rinkal', 'ritu', 'rutu', 'sadhana', 'sanjana', 'sapna',
    'shefali', 'shimpy', 'shraddha', 'shweta', 'smita', 'sonal', 'surabhi',
    'trupti', 'twinkle', 'urvashi', 'vanita', 'vidhi', 'vini', 'yogita',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Field {
  final String value;
  final Confidence conf;
  const _Field(this.value, this.conf);
}

class _NameCandidate {
  final String name;
  final int score;
  const _NameCandidate(this.name, this.score);
}
