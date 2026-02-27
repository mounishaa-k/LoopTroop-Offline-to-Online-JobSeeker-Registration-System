import 'field_metadata.dart';
import 'education_entry.dart';
import 'experience_entry.dart';

class ExtractionResult {
  // Identity
  FieldValue<String>? fullName;
  FieldValue<String>? givenName;
  FieldValue<String>? familyName;
  FieldValue<String>? otherNames;

  // Contact
  List<ContactField> phones;
  List<ContactField> emails;
  FieldValue<String>? address;
  List<ContactField> linkedinUrls;
  List<ContactField> githubUrls;
  List<ContactField> websiteUrls;

  // Demographics (optional)
  FieldValue<String>? dob;
  FieldValue<String>? gender;
  FieldValue<String>? nationalId;

  // Lists
  List<EducationEntry> education;
  List<ExperienceEntry> experience;
  List<String> skills;
  List<String> languages;
  List<String> certifications;
  List<String> projects;

  // Narrative
  FieldValue<String>? summary;

  // Other structured
  FieldValue<String>? availability;
  FieldValue<String>? noticePeriod;
  FieldValue<String>? expectedSalary;

  // Flags
  bool isHandwritten;
  bool hasLowOcrQuality;

  // Raw
  List<PageText> pagesTexts;

  ExtractionResult({
    this.fullName,
    this.givenName,
    this.familyName,
    this.otherNames,
    List<ContactField>? phones,
    List<ContactField>? emails,
    this.address,
    List<ContactField>? linkedinUrls,
    List<ContactField>? githubUrls,
    List<ContactField>? websiteUrls,
    this.dob,
    this.gender,
    this.nationalId,
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
    List<String>? skills,
    List<String>? languages,
    List<String>? certifications,
    List<String>? projects,
    this.summary,
    this.availability,
    this.noticePeriod,
    this.expectedSalary,
    this.isHandwritten = false,
    this.hasLowOcrQuality = false,
    List<PageText>? pagesTexts,
  })  : phones = phones ?? [],
        emails = emails ?? [],
        linkedinUrls = linkedinUrls ?? [],
        githubUrls = githubUrls ?? [],
        websiteUrls = websiteUrls ?? [],
        education = education ?? [],
        experience = experience ?? [],
        skills = skills ?? [],
        languages = languages ?? [],
        certifications = certifications ?? [],
        projects = projects ?? [],
        pagesTexts = pagesTexts ?? [];

  bool get isComplete =>
      fullName != null &&
      fullName!.value.isNotEmpty &&
      (phones.isNotEmpty || emails.isNotEmpty);

  String get rawText {
    final parts = <String>[];
    for (var i = 0; i < pagesTexts.length; i++) {
      parts.add('--- Page ${i + 1} ---\n${pagesTexts[i].text}');
    }
    return parts.join('\n\n');
  }

  Map<String, dynamic> toJson() => {
        'full_name': fullName?.toJson((v) => v),
        'given_name': givenName?.toJson((v) => v),
        'family_name': familyName?.toJson((v) => v),
        'other_names': otherNames?.toJson((v) => v),
        'phones': phones.map((e) => e.toJson()).toList(),
        'emails': emails.map((e) => e.toJson()).toList(),
        'address': address?.toJson((v) => v),
        'linkedin_urls': linkedinUrls.map((e) => e.toJson()).toList(),
        'github_urls': githubUrls.map((e) => e.toJson()).toList(),
        'website_urls': websiteUrls.map((e) => e.toJson()).toList(),
        'dob': dob?.toJson((v) => v),
        'gender': gender?.toJson((v) => v),
        'national_id': nationalId?.toJson((v) => v),
        'education': education.map((e) => e.toJson()).toList(),
        'experience': experience.map((e) => e.toJson()).toList(),
        'skills': skills,
        'languages': languages,
        'certifications': certifications,
        'projects': projects,
        'summary': summary?.toJson((v) => v),
        'availability': availability?.toJson((v) => v),
        'notice_period': noticePeriod?.toJson((v) => v),
        'expected_salary': expectedSalary?.toJson((v) => v),
        'is_handwritten': isHandwritten,
        'has_low_ocr_quality': hasLowOcrQuality,
        'pages_texts': pagesTexts.map((e) => e.toJson()).toList(),
      };

  factory ExtractionResult.fromJson(Map<String, dynamic> j) {
    FieldValue<String>? fv(String key) {
      final raw = j[key];
      if (raw == null) return null;
      return FieldValue.fromJsonString(raw as Map<String, dynamic>);
    }

    List<ContactField> cf(String key) {
      final raw = j[key];
      if (raw == null) return [];
      return (raw as List)
          .map((e) => ContactField.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ExtractionResult(
      fullName: fv('full_name'),
      givenName: fv('given_name'),
      familyName: fv('family_name'),
      otherNames: fv('other_names'),
      phones: cf('phones'),
      emails: cf('emails'),
      address: fv('address'),
      linkedinUrls: cf('linkedin_urls'),
      githubUrls: cf('github_urls'),
      websiteUrls: cf('website_urls'),
      dob: fv('dob'),
      gender: fv('gender'),
      nationalId: fv('national_id'),
      education: (j['education'] as List? ?? [])
          .map((e) => EducationEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      experience: (j['experience'] as List? ?? [])
          .map((e) => ExperienceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: List<String>.from(j['skills'] as List? ?? []),
      languages: List<String>.from(j['languages'] as List? ?? []),
      certifications: List<String>.from(j['certifications'] as List? ?? []),
      projects: List<String>.from(j['projects'] as List? ?? []),
      summary: fv('summary'),
      availability: fv('availability'),
      noticePeriod: fv('notice_period'),
      expectedSalary: fv('expected_salary'),
      isHandwritten: j['is_handwritten'] as bool? ?? false,
      hasLowOcrQuality: j['has_low_ocr_quality'] as bool? ?? false,
      pagesTexts: (j['pages_texts'] as List? ?? [])
          .map((e) => PageText.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
