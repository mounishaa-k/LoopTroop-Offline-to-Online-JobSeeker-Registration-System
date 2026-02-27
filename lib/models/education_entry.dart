import 'field_metadata.dart';

class EducationEntry {
  String degree;
  String specialization;
  String institution;
  String startYear;
  String endYear;
  String grade;
  int pageIndex;
  FieldMetadata metadata;

  EducationEntry({
    this.degree = '',
    this.specialization = '',
    this.institution = '',
    this.startYear = '',
    this.endYear = '',
    this.grade = '',
    this.pageIndex = 0,
    FieldMetadata? metadata,
  }) : metadata = metadata ?? FieldMetadata.defaultMeta;

  EducationEntry copyWith({
    String? degree,
    String? specialization,
    String? institution,
    String? startYear,
    String? endYear,
    String? grade,
    int? pageIndex,
    FieldMetadata? metadata,
  }) =>
      EducationEntry(
        degree: degree ?? this.degree,
        specialization: specialization ?? this.specialization,
        institution: institution ?? this.institution,
        startYear: startYear ?? this.startYear,
        endYear: endYear ?? this.endYear,
        grade: grade ?? this.grade,
        pageIndex: pageIndex ?? this.pageIndex,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'specialization': specialization,
        'institution': institution,
        'start_year': startYear,
        'end_year': endYear,
        'grade': grade,
        'page_index': pageIndex,
        'metadata': metadata.toJson(),
      };

  factory EducationEntry.fromJson(Map<String, dynamic> j) => EducationEntry(
        degree: j['degree'] as String? ?? '',
        specialization: j['specialization'] as String? ?? '',
        institution: j['institution'] as String? ?? '',
        startYear: j['start_year'] as String? ?? '',
        endYear: j['end_year'] as String? ?? '',
        grade: j['grade'] as String? ?? '',
        pageIndex: j['page_index'] as int? ?? 0,
        metadata: FieldMetadata.fromJson(
            j['metadata'] as Map<String, dynamic>? ?? {}),
      );

  @override
  String toString() =>
      '$degree${specialization.isNotEmpty ? " in $specialization" : ""} — $institution ($startYear${endYear.isNotEmpty ? "–$endYear" : ""})';
}
