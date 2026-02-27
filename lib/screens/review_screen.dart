import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/field_metadata.dart';
import '../models/resume_record.dart';
import '../models/extraction_result.dart';
import '../models/education_entry.dart';
import '../services/validation_service.dart';
import '../state/app_state.dart';
import '../utils/helpers.dart';

class ReviewScreen extends StatefulWidget {
  final ResumeRecord record;
  const ReviewScreen({super.key, required this.record});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late ResumeRecord _record;
  late ExtractionResult _ext;
  bool _saving = false;

  // Text controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _educationCtrl;
  late TextEditingController _givenCtrl;
  late TextEditingController _familyCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _availCtrl;
  late TextEditingController _salaryCtrl;
  late TextEditingController _skillsCtrl;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _ext = _record.extracted;
    _nameCtrl = TextEditingController(text: _ext.fullName?.value ?? '');
    _phoneCtrl = TextEditingController(
        text: _ext.phones.isNotEmpty ? _ext.phones.first.value : '');
    _emailCtrl = TextEditingController(
        text: _ext.emails.isNotEmpty ? _ext.emails.first.value : '');
    _educationCtrl = TextEditingController(
        text: _ext.education.isNotEmpty
            ? '${_ext.education.first.degree} ${_ext.education.first.specialization}'
                .trim()
            : '');
    _givenCtrl = TextEditingController(text: _ext.givenName?.value ?? '');
    _familyCtrl = TextEditingController(text: _ext.familyName?.value ?? '');
    _summaryCtrl = TextEditingController(text: _ext.summary?.value ?? '');
    _availCtrl = TextEditingController(text: _ext.availability?.value ?? '');
    _salaryCtrl = TextEditingController(text: _ext.expectedSalary?.value ?? '');
    _skillsCtrl = TextEditingController(text: _ext.skills.join(', '));
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _educationCtrl,
      _givenCtrl,
      _familyCtrl,
      _summaryCtrl,
      _availCtrl,
      _salaryCtrl,
      _skillsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  FieldMetadata _meta(String v) => FieldMetadata(
        confidence: 1.0,
        sourcePage: 0,
        rawSnippet: v,
        extractionMethod: 'manual',
      );

  FieldValue<String>? _fv(TextEditingController c, FieldValue<String>? orig) {
    final v = c.text.trim();
    if (v.isEmpty) return orig;
    return FieldValue<String>(
      value: v,
      metadata: orig?.metadata ?? _meta(v),
    );
  }

  ResumeRecord _buildRecord() {
    final skillsList = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final edu = _educationCtrl.text.trim();

    final eduEntries = edu.isNotEmpty
        ? [
            EducationEntry(
              degree: edu,
              institution: _ext.education.isNotEmpty
                  ? _ext.education.first.institution
                  : '',
              startYear: _ext.education.isNotEmpty
                  ? _ext.education.first.startYear
                  : '',
              endYear:
                  _ext.education.isNotEmpty ? _ext.education.first.endYear : '',
              grade:
                  _ext.education.isNotEmpty ? _ext.education.first.grade : '',
              pageIndex: 0,
              metadata: _ext.education.isNotEmpty
                  ? _ext.education.first.metadata
                  : _meta(edu),
            )
          ]
        : _ext.education;

    final phones = phone.isNotEmpty
        ? [
            ContactField(
              value: phone,
              label: 'mobile',
              metadata: _ext.phones.isNotEmpty
                  ? _ext.phones.first.metadata
                  : _meta(phone),
            )
          ]
        : _ext.phones;

    final emails = email.isNotEmpty
        ? [
            ContactField(
              value: email,
              label: 'primary',
              metadata: _ext.emails.isNotEmpty
                  ? _ext.emails.first.metadata
                  : _meta(email),
            )
          ]
        : _ext.emails;

    final updated = ExtractionResult(
      fullName: _fv(_nameCtrl, _ext.fullName),
      givenName: _fv(_givenCtrl, _ext.givenName),
      familyName: _fv(_familyCtrl, _ext.familyName),
      phones: phones,
      emails: emails,
      address: _ext.address,
      linkedinUrls: _ext.linkedinUrls,
      githubUrls: _ext.githubUrls,
      websiteUrls: _ext.websiteUrls,
      dob: _ext.dob,
      gender: _ext.gender,
      education: eduEntries,
      experience: _ext.experience,
      skills: skillsList.isNotEmpty ? skillsList : _ext.skills,
      languages: _ext.languages,
      certifications: _ext.certifications,
      projects: _ext.projects,
      summary: _fv(_summaryCtrl, _ext.summary),
      availability: _fv(_availCtrl, _ext.availability),
      noticePeriod: _ext.noticePeriod,
      expectedSalary: _fv(_salaryCtrl, _ext.expectedSalary),
      isHandwritten: _ext.isHandwritten,
      hasLowOcrQuality: _ext.hasLowOcrQuality,
      pagesTexts: _ext.pagesTexts,
    );

    return ResumeRecord(
      id: _record.id,
      displayId: _record.displayId,
      rawText: _record.rawText,
      pagesTexts: _record.pagesTexts,
      images: _record.images,
      extracted: updated,
      extractionMetadata: _record.extractionMetadata,
      status: 'pending',
      createdAt: _record.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    // Validate phone/email if not empty
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (phone.isNotEmpty && !ValidationService.isValidPhone(phone)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid phone number')));
      return;
    }
    if (email.isNotEmpty && !ValidationService.isValidEmail(email)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid email address')));
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = _buildRecord();
      await context.read<AppState>().saveRecord(saved);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Record saved!'),
            backgroundColor: AppTheme.highConfidence,
          ),
        );
        // Navigate to QR result screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/qr_result',
          (route) => route.settings.name == '/home',
          arguments: saved,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Review & Save',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: Text('Save',
                  style: GoogleFonts.inter(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _banner(),
            const SizedBox(height: 16),
            _section('Identity', Icons.person_outline, [
              _field('Full Name *', _nameCtrl,
                  meta: _ext.fullName?.metadata, required: true),
              _field('Given Name', _givenCtrl, meta: _ext.givenName?.metadata),
              _field('Family Name', _familyCtrl,
                  meta: _ext.familyName?.metadata),
            ]),
            _section('Contact', Icons.contact_phone_outlined, [
              _field('Phone', _phoneCtrl,
                  meta: _ext.phones.isNotEmpty
                      ? _ext.phones.first.metadata
                      : null,
                  keyboard: TextInputType.phone),
              _field('Email', _emailCtrl,
                  meta: _ext.emails.isNotEmpty
                      ? _ext.emails.first.metadata
                      : null,
                  keyboard: TextInputType.emailAddress),
            ]),
            _section('Education', Icons.school_outlined, [
              _field('Degree / Qualification', _educationCtrl,
                  meta: _ext.education.isNotEmpty
                      ? _ext.education.first.metadata
                      : null),
              if (_ext.education.isNotEmpty &&
                  _ext.education.first.institution.isNotEmpty)
                _infoRow('Institution', _ext.education.first.institution),
              if (_ext.education.isNotEmpty &&
                  _ext.education.first.endYear.isNotEmpty)
                _infoRow('Year',
                    '${_ext.education.first.startYear}–${_ext.education.first.endYear}'),
            ]),
            _section('Skills', Icons.star_outline, [
              _field('Skills (comma separated)', _skillsCtrl, maxLines: 2),
            ]),
            if (_ext.experience.isNotEmpty)
              _section('Experience', Icons.work_outline, [
                ..._ext.experience.map((e) => _infoRow(
                    e.title.isNotEmpty ? e.title : 'Role',
                    '${e.employer}${e.startDate.isNotEmpty ? " (${e.startDate}–${e.endDate})" : ""}')),
              ]),
            _section('Other', Icons.more_horiz, [
              _field('Availability', _availCtrl,
                  meta: _ext.availability?.metadata),
              _field('Expected Salary', _salaryCtrl,
                  meta: _ext.expectedSalary?.metadata),
              _field('Summary / Objective', _summaryCtrl,
                  meta: _ext.summary?.metadata, maxLines: 3),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save Record',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    final conf = _ext.fullName?.metadata.confidence ?? 0;
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_fix_high,
                color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Extraction Complete',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(
                  'Review and edit fields below before saving',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF8899CC), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${(conf * 100).round()}%',
                  style: GoogleFonts.inter(
                      color: AppTheme.confidenceColor(conf),
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              Text('conf.',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF8899CC), fontSize: 10)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(title.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.8)),
            ],
          ),
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    FieldMetadata? meta,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    final conf = meta?.confidence;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label${required ? " *" : ""}',
                style: GoogleFonts.inter(
                    color: required
                        ? const Color(0xFFBBCCFF)
                        : const Color(0xFF8899CC),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (conf != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.confidenceColor(conf).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(conf * 100).round()}%',
                    style: GoogleFonts.inter(
                        color: AppTheme.confidenceColor(conf),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppTheme.cardBorderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryColor)),
            ),
          ),
          if (meta?.rawSnippet.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'Source: "${Helpers.truncate(meta!.rawSnippet, 55)}"',
                style: GoogleFonts.inter(
                    color: const Color(0xFF4455AA), fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.inter(
                    color: const Color(0xFF8899CC), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
