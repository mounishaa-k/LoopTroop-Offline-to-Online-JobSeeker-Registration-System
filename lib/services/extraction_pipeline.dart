import 'dart:math';
import '../constants.dart';
import '../models/field_metadata.dart';
import '../models/extraction_result.dart';
import '../models/education_entry.dart';
import '../models/experience_entry.dart';
import '../utils/helpers.dart';

/// 7-step hybrid extraction pipeline.
/// Step 1: Preprocess — normalize text, strip repeated headers/footers.
/// Step 2: Regex   — emails, phones, URLs, dates.
/// Step 3: Keywords — fuzzy section-heading detection.
/// Step 4: Blocks  — parse section blocks for sub-fields.
/// Step 5: Name    — heuristic top-line name detection.
/// Step 6: Merge   — cross-page section merging.
/// Step 7: Build   — assemble ExtractionResult with confidence scores.
class ExtractionPipeline {
  // ── Regex patterns ──────────────────────────────────────────────────────
  static final _emailRe =
      RegExp(r'[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}', caseSensitive: false);
  static final _phoneRe =
      RegExp(r'(?:\+[\d\s\-().]{7,18}|\b0[\d\s\-().]{8,16}\b|'
          r'\b\(?\d{3}\)?[\s.\-]?\d{3}[\s.\-]?\d{4}\b)');
  static final _linkedinRe = RegExp(
      r'(?:https?://)?(?:www\.)?linkedin\.com/in/[\w\-]+',
      caseSensitive: false);
  static final _githubRe = RegExp(
      r'(?:https?://)?(?:www\.)?github\.com/[\w\-]+',
      caseSensitive: false);
  static final _yearRangeRe = RegExp(
      r'\b((?:19|20)\d{2})\s*[-–—/to]+\s*((?:19|20)\d{2}|[Pp]resent|[Cc]urrent|[Nn]ow)\b');
  static final _singleYearRe = RegExp(r'\b((?:19|20)\d{2})\b');
  static final _gpaRe = RegExp(r'GPA\s*[:\-]?\s*(\d+\.?\d*)\s*/\s*(\d+\.?\d*)',
      caseSensitive: false);
  static final _gradeRe = RegExp(
      r'\b(First Class|Second Class|Third Class|Distinction|Merit|Pass|Credit|Pass|'
      r'\d+\.?\d*\s*%|\d+\.?\d*\s*/\s*\d+\.?\d*)\b',
      caseSensitive: false);
  static final _salaryRe = RegExp(
      r'(?:expected salary|salary expectation|ctc|package)\s*[:\-]?\s*([^\n]+)',
      caseSensitive: false);
  static final _noticePeriodRe =
      RegExp(r'notice period\s*[:\-]?\s*([^\n]+)', caseSensitive: false);
  static final _availabilityRe =
      RegExp(r'availability\s*[:\-]?\s*([^\n]+)', caseSensitive: false);
  static final _dobRe = RegExp(
      r'(?:dob|date of birth|born|d\.o\.b)\s*[:\-]?\s*(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}|\d{1,2}\s+\w+\s+\d{4})',
      caseSensitive: false);
  static final _genderRe = RegExp(
      r'(?:gender|sex)\s*[:\-]?\s*(male|female|m|f|non-binary|prefer not to say)',
      caseSensitive: false);

  // ── Section categories ───────────────────────────────────────────────────
  static const Map<String, List<String>> _sectionKeywords = {
    'summary': AppConstants.summaryKeywords,
    'education': AppConstants.educationKeywords,
    'experience': AppConstants.experienceKeywords,
    'skills': AppConstants.skillsKeywords,
    'languages': AppConstants.languagesKeywords,
    'certifications': AppConstants.certificationsKeywords,
    'projects': AppConstants.projectsKeywords,
    'achievements': AppConstants.achievementsKeywords,
    'references': AppConstants.referencesKeywords,
  };

  // ── Public entry point ───────────────────────────────────────────────────
  static ExtractionResult extract(List<PageText> pages) {
    // Step 1: Preprocess
    final preprocessed = _preprocess(pages);

    // Step 2: Regex extraction
    final regexHits = _runRegex(preprocessed);

    // Step 3 + 4: Section detection and block extraction
    final sections = _detectSections(preprocessed);

    // Step 5: Name detection
    final nameResult = _detectName(preprocessed, regexHits);

    // Step 6: Multi-page merge already handled in section detection

    // Step 7: Assemble result
    return _buildResult(nameResult, regexHits, sections, preprocessed, pages);
  }

  // ── Step 1: Preprocess ───────────────────────────────────────────────────
  static List<_ProcessedPage> _preprocess(List<PageText> pages) {
    // Build line frequency map to detect repeated headers/footers
    final lineFreq = <String, int>{};
    for (final p in pages) {
      for (final line in p.text.split('\n')) {
        final key = line.trim().toLowerCase();
        if (key.isNotEmpty) lineFreq[key] = (lineFreq[key] ?? 0) + 1;
      }
    }
    final repeatedLines = lineFreq.entries
        .where((e) => e.value >= pages.length && pages.length > 1)
        .map((e) => e.key)
        .toSet();

    return pages.map((p) {
      final lines = p.text
          .split('\n')
          .map((l) => l.trim())
          .where(
              (l) => l.isNotEmpty && !repeatedLines.contains(l.toLowerCase()))
          .toList();
      return _ProcessedPage(pageIndex: p.pageIndex, lines: lines);
    }).toList();
  }

  // ── Step 2: Regex extraction ─────────────────────────────────────────────
  static _RegexHits _runRegex(List<_ProcessedPage> pages) {
    final emails = <ContactField>[];
    final phones = <ContactField>[];
    final linkedins = <ContactField>[];
    final githubs = <ContactField>[];
    final urls = <ContactField>[];
    String? salary, notice, availability, dob, gender;
    int? salaryPage, noticePage, availPage, dobPage, genderPage;

    final emailSeen = <String>{};
    final phoneSeen = <String>{};
    final urlSeen = <String>{};

    for (final p in pages) {
      final text = p.lines.join('\n');

      for (final m in _linkedinRe.allMatches(text)) {
        final v = m.group(0)!;
        if (!urlSeen.contains(v)) {
          urlSeen.add(v);
          linkedins.add(ContactField(
              value: v,
              label: 'linkedin',
              metadata: FieldMetadata(
                  confidence: 0.95,
                  sourcePage: p.pageIndex,
                  rawSnippet: _snippet(text, m.start),
                  extractionMethod: AppConstants.methodRegex)));
        }
      }
      for (final m in _githubRe.allMatches(text)) {
        final v = m.group(0)!;
        if (!urlSeen.contains(v)) {
          urlSeen.add(v);
          githubs.add(ContactField(
              value: v,
              label: 'github',
              metadata: FieldMetadata(
                  confidence: 0.95,
                  sourcePage: p.pageIndex,
                  rawSnippet: _snippet(text, m.start),
                  extractionMethod: AppConstants.methodRegex)));
        }
      }

      for (final m in _emailRe.allMatches(text)) {
        final v = m.group(0)!.toLowerCase();
        if (!emailSeen.contains(v)) {
          emailSeen.add(v);
          final label = _guessEmailLabel(v, text, m.start);
          emails.add(ContactField(
              value: v,
              label: label,
              metadata: FieldMetadata(
                  confidence: 0.97,
                  sourcePage: p.pageIndex,
                  rawSnippet: _snippet(text, m.start),
                  extractionMethod: AppConstants.methodRegex)));
        }
      }
      for (final m in _phoneRe.allMatches(text)) {
        final v = m.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim();
        final normalized = v.replaceAll(RegExp(r'[^\d+]'), '');
        if (normalized.length >= 7 && !phoneSeen.contains(normalized)) {
          phoneSeen.add(normalized);
          final label = _guessPhoneLabel(text, m.start);
          phones.add(ContactField(
              value: v,
              label: label,
              metadata: FieldMetadata(
                  confidence: 0.93,
                  sourcePage: p.pageIndex,
                  rawSnippet: _snippet(text, m.start),
                  extractionMethod: AppConstants.methodRegex)));
        }
      }

      // Other structured fields
      final salM = _salaryRe.firstMatch(text);
      if (salM != null && salary == null) {
        salary = salM.group(1)?.trim();
        salaryPage = p.pageIndex;
      }
      final notM = _noticePeriodRe.firstMatch(text);
      if (notM != null && notice == null) {
        notice = notM.group(1)?.trim();
        noticePage = p.pageIndex;
      }
      final avM = _availabilityRe.firstMatch(text);
      if (avM != null && availability == null) {
        availability = avM.group(1)?.trim();
        availPage = p.pageIndex;
      }
      final dobM = _dobRe.firstMatch(text);
      if (dobM != null && dob == null) {
        dob = dobM.group(1)?.trim();
        dobPage = p.pageIndex;
      }
      final genM = _genderRe.firstMatch(text);
      if (genM != null && gender == null) {
        gender = genM.group(1)?.trim();
        genderPage = p.pageIndex;
      }
    }

    return _RegexHits(
      emails: emails,
      phones: phones,
      linkedins: linkedins,
      githubs: githubs,
      urls: urls,
      salary: salary,
      salaryPage: salaryPage,
      notice: notice,
      noticePage: noticePage,
      availability: availability,
      availPage: availPage,
      dob: dob,
      dobPage: dobPage,
      gender: gender,
      genderPage: genderPage,
    );
  }

  // ── Step 3+4: Section detection and block extraction ─────────────────────
  static Map<String, _SectionBlock> _detectSections(
      List<_ProcessedPage> pages) {
    // Collect all lines with page metadata
    final allLines = <_AnnotatedLine>[];
    for (final p in pages) {
      for (final line in p.lines) {
        allLines.add(_AnnotatedLine(line: line, pageIndex: p.pageIndex));
      }
    }

    // Detect section boundaries
    final boundaries = <int, String>{};
    for (int i = 0; i < allLines.length; i++) {
      final line = allLines[i].line;
      final category = _classifyHeading(line);
      if (category != null) boundaries[i] = category;
    }

    // Extract blocks between boundaries
    final sections = <String, _SectionBlock>{};
    final boundaryIndices = boundaries.keys.toList()..sort();

    for (int bi = 0; bi < boundaryIndices.length; bi++) {
      final start = boundaryIndices[bi];
      final end = bi + 1 < boundaryIndices.length
          ? boundaryIndices[bi + 1]
          : allLines.length;
      final category = boundaries[start]!;

      final blockLines = allLines
          .sublist(start + 1, end)
          .where((l) => l.line.trim().isNotEmpty)
          .toList();

      if (blockLines.isEmpty) continue;

      final existing = sections[category];
      if (existing != null) {
        // Merge cross-page sections
        sections[category] = _SectionBlock(
          category: category,
          lines: [...existing.lines, ...blockLines],
          sourcePages: {
            ...existing.sourcePages,
            ...blockLines.map((l) => l.pageIndex).toSet()
          }.toList(),
          rawHeadingSnippet: existing.rawHeadingSnippet,
        );
      } else {
        sections[category] = _SectionBlock(
          category: category,
          lines: blockLines,
          sourcePages: blockLines.map((l) => l.pageIndex).toSet().toList(),
          rawHeadingSnippet: allLines[start].line,
        );
      }
    }

    return sections;
  }

  static String? _classifyHeading(String line) {
    final trimmed = line.trim();
    // Must be reasonably short to be a heading (< 80 chars)
    if (trimmed.length > 80 || trimmed.length < 3) return null;
    // Heuristic: heading is mostly uppercase or title case
    final upper = trimmed.toUpperCase();
    final isUpper = trimmed == upper && trimmed.contains(RegExp(r'[A-Z]'));
    final isTitleish = RegExp(r'^[A-Z]').hasMatch(trimmed);
    if (!isUpper && !isTitleish) return null;

    for (final entry in _sectionKeywords.entries) {
      if (Helpers.fuzzyMatchesAny(trimmed, entry.value, maxDist: 2)) {
        return entry.key;
      }
    }
    return null;
  }

  // ── Step 5: Name detection ───────────────────────────────────────────────
  static _NameResult _detectName(
      List<_ProcessedPage> pages, _RegexHits regexHits) {
    if (pages.isEmpty) return _NameResult(null, null, null);

    final firstPage = pages.first;
    // Known contact-like patterns to skip
    final skipRe = RegExp(
        r'[@\d\+\-\(\)]{3,}|https?://|www\.|linkedin|github|'
        r'(education|experience|skills|summary|profile|objective)',
        caseSensitive: false);

    String? fullName;
    int? namePage;
    String? rawSnippet;

    for (int i = 0; i < min(8, firstPage.lines.length); i++) {
      final line = firstPage.lines[i].trim();
      if (line.isEmpty || skipRe.hasMatch(line)) continue;
      if (line.contains('@') || line.contains('http')) continue;
      // Remove known contact field labels
      if (RegExp(r'^(phone|email|mobile|tel|fax|address|name)[\s:]+',
              caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }
      // Must contain at least 2 words with first letter capitalized
      final words =
          line.split(RegExp(r'[\s,]+')).where((w) => w.isNotEmpty).toList();
      final capWords = words
          .where((w) =>
              w.length > 1 &&
              w[0] == w[0].toUpperCase() &&
              RegExp(r'[A-Za-z]').hasMatch(w[0]))
          .toList();
      if (capWords.length >= 2 && words.length <= 6) {
        // Strip titles like Dr., Prof., Mr., Mrs., Ms.
        final stripped = line.replaceAll(
            RegExp(r'^(Dr\.?|Prof\.?|Mr\.?|Mrs\.?|Ms\.?|Mx\.?)\s+',
                caseSensitive: false),
            '');
        fullName = stripped.trim();
        namePage = firstPage.pageIndex;
        rawSnippet = line;
        break;
      }
    }

    // Split into given/family name if 2 words
    String? given, family;
    if (fullName != null) {
      final parts = fullName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        given = parts.first;
        family = parts.last;
      }
    }

    return _NameResult(fullName, given, family,
        pageIndex: namePage ?? 0, rawSnippet: rawSnippet ?? fullName ?? '');
  }

  // ── Education parser ─────────────────────────────────────────────────────
  static List<EducationEntry> _parseEducation(
      _SectionBlock block, List<_ProcessedPage> pages) {
    final entries = <EducationEntry>[];
    final text = block.lines.map((l) => l.line).join('\n');
    final sourcePages = block.sourcePages;

    // Split by blank lines or degree keywords
    final chunks = text
        .split(RegExp(r'\n\s*\n'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    // Also try splitting by degree keywords at line start
    if (chunks.length == 1) {
      final lines = block.lines.map((l) => l.line).toList();
      final degChunks = _splitByDegreeKeywords(lines);
      if (degChunks.length > 1) {
        for (final chunk in degChunks) {
          final e = _parseEduChunk(chunk.join('\n'), sourcePages);
          if (e != null) entries.add(e);
        }
        return entries;
      }
    }

    // Table detection: if header row has "Degree / Institution / Year" pattern
    if (_looksLikeTable(text)) {
      return _parseEduTable(block);
    }

    for (final chunk in chunks) {
      final e = _parseEduChunk(chunk, sourcePages);
      if (e != null) entries.add(e);
    }
    return entries;
  }

  static List<List<String>> _splitByDegreeKeywords(List<String> lines) {
    final chunks = <List<String>>[];
    var current = <String>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      final isDegLine = AppConstants.degreeKeywords
          .any((kw) => lower.startsWith(kw) || lower.contains(' $kw '));
      if (isDegLine && current.isNotEmpty) {
        chunks.add(current);
        current = [];
      }
      current.add(line);
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  static EducationEntry? _parseEduChunk(String chunk, List<int> sourcePages) {
    if (chunk.trim().isEmpty) return null;
    final lines = chunk
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    String degree = '', specialization = '', institution = '';
    String startYear = '', endYear = '', grade = '';

    // Year range
    final yearM = _yearRangeRe.firstMatch(chunk);
    if (yearM != null) {
      startYear = yearM.group(1) ?? '';
      final yr2 = yearM.group(2) ?? '';
      endYear = RegExp(r'\d{4}').hasMatch(yr2)
          ? yr2
          : (yr2.toLowerCase().contains('present') ||
                  yr2.toLowerCase().contains('current')
              ? 'Present'
              : '');
    } else {
      final yearMs = _singleYearRe.allMatches(chunk).toList();
      if (yearMs.length == 1) endYear = yearMs.first.group(0)!;
    }

    // Grade / GPA
    final gpaM = _gpaRe.firstMatch(chunk);
    if (gpaM != null) {
      grade = '${gpaM.group(1)}/${gpaM.group(2)}';
    } else {
      final gradeM = _gradeRe.firstMatch(chunk);
      if (gradeM != null) grade = gradeM.group(0)!;
    }

    // Degree detection from first lines
    for (final line in lines.take(3)) {
      final lower = line.toLowerCase();
      final degKw = AppConstants.degreeKeywords
          .where((kw) => lower.contains(kw))
          .toList();
      if (degKw.isNotEmpty) {
        degree = _cleanDegreeTitle(line);
        // Extract specialization after "in" or "|"
        final inMatch = RegExp(r'\bin\s+([A-Z][^\|,\n]+)', caseSensitive: false)
            .firstMatch(line);
        if (inMatch != null) specialization = inMatch.group(1)?.trim() ?? '';
        break;
      }
    }
    if (degree.isEmpty && lines.isNotEmpty) {
      degree = _cleanDegreeTitle(lines.first);
    }

    // Institution: look for University/College/Institute/School keywords
    final instRe = RegExp(
        r'\b(University|College|Institute|School|Academy|Polytechnic|'
        r'MIT|Stanford|Oxford|Cambridge|Harvard|UCT)\w*\b[^,\n]*',
        caseSensitive: false);
    final instM = instRe.firstMatch(chunk);
    if (instM != null) institution = instM.group(0)!.trim();

    // Remove year and grade from institution
    institution = institution.replaceAll(_yearRangeRe, '').trim();

    if (degree.isEmpty && institution.isEmpty) return null;

    final pageIdxs = sourcePages;
    return EducationEntry(
      degree: degree,
      specialization: specialization,
      institution: institution,
      startYear: startYear,
      endYear: endYear,
      grade: grade,
      pageIndex: pageIdxs.isNotEmpty ? pageIdxs.first : 0,
      metadata: FieldMetadata(
        confidence: 0.70,
        sourcePage: pageIdxs.length == 1 ? pageIdxs.first : pageIdxs,
        rawSnippet: Helpers.truncate(chunk, 120),
        extractionMethod: AppConstants.methodKeyword,
      ),
    );
  }

  static bool _looksLikeTable(String text) =>
      text.contains(RegExp(r'\|\s+\w')) || text.contains('\t');

  static List<EducationEntry> _parseEduTable(_SectionBlock block) {
    final entries = <EducationEntry>[];
    final rows = block.lines.map((l) => l.line).toList();
    // Skip header row
    for (final row in rows.skip(1)) {
      final cells = row.split(RegExp(r'\||\t')).map((c) => c.trim()).toList();
      if (cells.length >= 2) {
        entries.add(EducationEntry(
          degree: cells.isNotEmpty ? cells[0] : '',
          institution: cells.length > 1 ? cells[1] : '',
          endYear: cells.length > 2 ? cells[2] : '',
          grade: cells.length > 3 ? cells[3] : '',
          metadata: FieldMetadata(
            confidence: 0.65,
            sourcePage:
                block.sourcePages.isNotEmpty ? block.sourcePages.first : 0,
            rawSnippet: Helpers.truncate(row, 100),
            extractionMethod: AppConstants.methodKeyword,
          ),
        ));
      }
    }
    return entries;
  }

  static String _cleanDegreeTitle(String line) {
    // Remove pipe-separated suffixes like institution and year
    return line.split(RegExp(r'\||—|-{2}|,\s*(?=\d{4})')).first.trim();
  }

  // ── Experience parser ────────────────────────────────────────────────────
  static List<ExperienceEntry> _parseExperience(
      _SectionBlock block, List<_ProcessedPage> pages) {
    final entries = <ExperienceEntry>[];
    final chunks = block.lines
        .map((l) => l.line)
        .join('\n')
        .split(RegExp(r'\n(?=\S)(?=[A-Z])|\n\s*\n'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    for (final chunk in chunks) {
      final e = _parseExpChunk(chunk, block.sourcePages);
      if (e != null) entries.add(e);
    }
    return entries;
  }

  static ExperienceEntry? _parseExpChunk(String chunk, List<int> sourcePages) {
    if (chunk.trim().isEmpty) return null;
    final lines = chunk
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    String title = '',
        employer = '',
        location = '',
        startDate = '',
        endDate = '';
    String description = '';

    // Year/date range
    final yearM = _yearRangeRe.firstMatch(chunk);
    final dateRe = RegExp(
        r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|June|July|August|September|October|November|December)'
        r'\s+\d{4}\s*[-–]\s*(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|June|July|August|September|October|November|December)\s+\d{4}|'
        r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|June|July|August|September|October|November|December)'
        r'\s+\d{4}\s*[-–]\s*(?:Present|Current|Now)',
        caseSensitive: false);
    final dateM = dateRe.firstMatch(chunk);

    if (dateM != null) {
      final full = dateM.group(0)!;
      final parts = full.split(RegExp(r'\s*[-–]\s*'));
      startDate = parts.isNotEmpty ? parts.first.trim() : '';
      endDate = parts.length > 1 ? parts.last.trim() : '';
    } else if (yearM != null) {
      startDate = yearM.group(1) ?? '';
      final yr2 = yearM.group(2) ?? '';
      endDate = RegExp(r'\d{4}').hasMatch(yr2) ? yr2 : 'Present';
    }

    // First line: "Title | Employer" or "Title — Employer" or "Title at Employer"
    final firstLine = lines.first;
    final separators =
        RegExp(r'\s*[|—–]\s*|\s+at\s+|\s+@\s+', caseSensitive: false);
    final splitParts = firstLine.split(separators);
    if (splitParts.length >= 2) {
      title = splitParts[0].trim();
      employer = splitParts[1].trim();
    } else {
      title = firstLine;
    }

    // Second line might be employer/location
    if (lines.length > 1 && employer.isEmpty) {
      final l2 = lines[1];
      if (!l2.startsWith('-') &&
          !l2.startsWith('•') &&
          !_yearRangeRe.hasMatch(l2)) {
        employer = l2.split(RegExp(r',|\s*\|\s*')).first.trim();
        location = l2.contains(',')
            ? l2
                .substring(l2.indexOf(',') + 1)
                .replaceAll(_yearRangeRe, '')
                .trim()
            : '';
      }
    }

    // Description: lines starting with - • or indented
    description = lines
        .skip(2)
        .where((l) =>
            l.startsWith('-') ||
            l.startsWith('•') ||
            l.startsWith('*') ||
            l.startsWith(' '))
        .map((l) => l.replaceFirst(RegExp(r'^[-•*\s]+'), '').trim())
        .join(' ');

    if (title.isEmpty && employer.isEmpty) return null;

    // Clean date info from title/employer
    title = title.replaceAll(_yearRangeRe, '').trim();
    employer = employer.replaceAll(_yearRangeRe, '').trim();

    return ExperienceEntry(
      title: title,
      employer: employer,
      location: location,
      startDate: startDate,
      endDate: endDate,
      description: description,
      pageIndex: sourcePages.isNotEmpty ? sourcePages.first : 0,
      metadata: FieldMetadata(
        confidence: 0.70,
        sourcePage: sourcePages.length == 1 ? sourcePages.first : sourcePages,
        rawSnippet: Helpers.truncate(chunk, 120),
        extractionMethod: AppConstants.methodKeyword,
      ),
    );
  }

  // ── Skills/Languages/Certifications/Projects parsers ────────────────────
  static List<String> _parseSkills(_SectionBlock block) {
    final text = block.lines.map((l) => l.line).join(', ');
    return text
        .split(RegExp(r',|;|\n|•|-|\|'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 1 && s.length < 60)
        .map((s) => Helpers.toTitleCase(s))
        .toSet()
        .toList();
  }

  static List<String> _parseList(_SectionBlock block) {
    final all = <String>[];
    for (final l in block.lines) {
      final stripped =
          l.line.replaceFirst(RegExp(r'^[-*•\d]+[.)]\s*'), '').trim();
      if (stripped.isNotEmpty) all.add(stripped);
    }
    return all;
  }

  static FieldValue<String>? _parseSummary(_SectionBlock block) {
    final text = block.lines.map((l) => l.line).join(' ').trim();
    if (text.isEmpty) return null;
    return FieldValue<String>(
      value: text,
      metadata: FieldMetadata(
        confidence: 0.75,
        sourcePage: block.sourcePages.isNotEmpty ? block.sourcePages.first : 0,
        rawSnippet: Helpers.truncate(text, 80),
        extractionMethod: AppConstants.methodKeyword,
      ),
    );
  }

  // ── Step 7: Assemble result ───────────────────────────────────────────────
  static ExtractionResult _buildResult(
    _NameResult nameResult,
    _RegexHits rx,
    Map<String, _SectionBlock> sections,
    List<_ProcessedPage> pages,
    List<PageText> originalPages,
  ) {
    FieldValue<String>? optFV(
            String? value, int? page, String method, double conf) =>
        value == null || value.isEmpty
            ? null
            : FieldValue<String>(
                value: value,
                metadata: FieldMetadata(
                    confidence: conf,
                    sourcePage: page ?? 0,
                    rawSnippet: value,
                    extractionMethod: method),
              );

    // Parse section blocks
    final education = sections['education'] != null
        ? _parseEducation(sections['education']!, pages)
        : <EducationEntry>[];

    final experience = sections['experience'] != null
        ? _parseExperience(sections['experience']!, pages)
        : <ExperienceEntry>[];

    final skills = sections['skills'] != null
        ? _parseSkills(sections['skills']!)
        : <String>[];

    final languages = sections['languages'] != null
        ? _parseList(sections['languages']!)
        : <String>[];

    final certifications = sections['certifications'] != null
        ? _parseList(sections['certifications']!)
        : <String>[];

    final projects = sections['projects'] != null
        ? _parseList(sections['projects']!)
        : <String>[];

    final achievements = sections['achievements'] != null
        ? _parseList(sections['achievements']!)
        : <String>[];

    final summary = sections['summary'] != null
        ? _parseSummary(sections['summary']!)
        : null;

    // Address heuristic: multi-line block near contact info
    FieldValue<String>? address;
    final allText = pages.map((p) => p.lines.join('\n')).join('\n');
    final addrRe = RegExp(
        r'\d+\s+[A-Z][a-zA-Z\s]+(?:Street|St|Avenue|Ave|Road|Rd|Lane|Ln|Drive|Dr|Boulevard|Blvd)\b[^\n]*',
        caseSensitive: false);
    final addrM = addrRe.firstMatch(allText);
    if (addrM != null) {
      address = FieldValue<String>(
        value: addrM.group(0)!.trim(),
        metadata: FieldMetadata(
            confidence: 0.70,
            sourcePage: 0,
            rawSnippet: addrM.group(0)!.trim(),
            extractionMethod: AppConstants.methodRegex),
      );
    }

    // Is handwritten heuristic
    final rawAllText = originalPages.map((p) => p.text).join(' ');
    final isHandwritten = OcrDependency.isPossiblyHandwritten(rawAllText);
    final hasLowQuality = rawAllText.length < 100;

    return ExtractionResult(
      fullName: nameResult.full == null
          ? null
          : FieldValue<String>(
              value: nameResult.full!,
              metadata: FieldMetadata(
                confidence: 0.65,
                sourcePage: nameResult.pageIndex,
                rawSnippet: nameResult.rawSnippet,
                extractionMethod: AppConstants.methodHeuristic,
              ),
            ),
      givenName: nameResult.given == null
          ? null
          : FieldValue<String>(
              value: nameResult.given!,
              metadata: FieldMetadata(
                  confidence: 0.60,
                  sourcePage: nameResult.pageIndex,
                  rawSnippet: nameResult.rawSnippet,
                  extractionMethod: AppConstants.methodHeuristic),
            ),
      familyName: nameResult.family == null
          ? null
          : FieldValue<String>(
              value: nameResult.family!,
              metadata: FieldMetadata(
                  confidence: 0.60,
                  sourcePage: nameResult.pageIndex,
                  rawSnippet: nameResult.rawSnippet,
                  extractionMethod: AppConstants.methodHeuristic),
            ),
      phones: rx.phones,
      emails: rx.emails,
      address: address,
      linkedinUrls: rx.linkedins,
      githubUrls: rx.githubs,
      websiteUrls: rx.urls,
      dob: optFV(rx.dob, rx.dobPage, AppConstants.methodRegex, 0.85),
      gender: optFV(rx.gender, rx.genderPage, AppConstants.methodRegex, 0.85),
      education: education,
      experience: experience,
      skills: skills,
      languages: languages,
      certifications: certifications,
      projects: [...projects, ...achievements],
      summary: summary,
      availability:
          optFV(rx.availability, rx.availPage, AppConstants.methodRegex, 0.90),
      noticePeriod:
          optFV(rx.notice, rx.noticePage, AppConstants.methodRegex, 0.90),
      expectedSalary:
          optFV(rx.salary, rx.salaryPage, AppConstants.methodRegex, 0.90),
      isHandwritten: isHandwritten,
      hasLowOcrQuality: hasLowQuality,
      pagesTexts: originalPages,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _snippet(String text, int pos) {
    final start = max(0, pos - 20);
    final end = min(text.length, pos + 60);
    return text.substring(start, end).replaceAll('\n', ' ').trim();
  }

  static String _guessEmailLabel(String email, String text, int pos) {
    final ctx = text.substring(max(0, pos - 30), pos).toLowerCase();
    if (ctx.contains('personal') ||
        ctx.contains('gmail') ||
        ctx.contains('yahoo') ||
        ctx.contains('hotmail')) {
      return 'personal';
    }
    if (ctx.contains('work') ||
        ctx.contains('office') ||
        ctx.contains('.edu') ||
        ctx.contains('.ac.')) {
      return 'work';
    }
    return 'primary';
  }

  static String _guessPhoneLabel(String text, int pos) {
    final ctx = text.substring(max(0, pos - 40), pos).toLowerCase();
    if (ctx.contains('mobile') ||
        ctx.contains('cell') ||
        ctx.contains('whatsapp')) {
      return 'mobile';
    }
    if (ctx.contains('home') || ctx.contains('landline')) {
      return 'home';
    }
    if (ctx.contains('work') || ctx.contains('office')) {
      return 'work';
    }
    return 'mobile';
  }
}

// Decoupled dependency to avoid circular import
class OcrDependency {
  static bool isPossiblyHandwritten(String text) {
    final words = text.split(RegExp(r'\s+'));
    final shortWords = words.where((w) => w.length == 1).length;
    return words.isNotEmpty && shortWords / words.length > 0.4;
  }
}

// ── Private data classes ───────────────────────────────────────────────────
class _ProcessedPage {
  final int pageIndex;
  final List<String> lines;
  _ProcessedPage({required this.pageIndex, required this.lines});
}

class _AnnotatedLine {
  final String line;
  final int pageIndex;
  _AnnotatedLine({required this.line, required this.pageIndex});
}

class _SectionBlock {
  final String category;
  final List<_AnnotatedLine> lines;
  final List<int> sourcePages;
  final String rawHeadingSnippet;

  _SectionBlock({
    required this.category,
    required this.lines,
    required this.sourcePages,
    required this.rawHeadingSnippet,
  });
}

class _RegexHits {
  final List<ContactField> emails;
  final List<ContactField> phones;
  final List<ContactField> linkedins;
  final List<ContactField> githubs;
  final List<ContactField> urls;
  final String? salary;
  final int? salaryPage;
  final String? notice;
  final int? noticePage;
  final String? availability;
  final int? availPage;
  final String? dob;
  final int? dobPage;
  final String? gender;
  final int? genderPage;

  const _RegexHits({
    required this.emails,
    required this.phones,
    required this.linkedins,
    required this.githubs,
    required this.urls,
    this.salary,
    this.salaryPage,
    this.notice,
    this.noticePage,
    this.availability,
    this.availPage,
    this.dob,
    this.dobPage,
    this.gender,
    this.genderPage,
  });
}

class _NameResult {
  final String? full;
  final String? given;
  final String? family;
  final int pageIndex;
  final String rawSnippet;

  _NameResult(this.full, this.given, this.family,
      {this.pageIndex = 0, this.rawSnippet = ''});
}
