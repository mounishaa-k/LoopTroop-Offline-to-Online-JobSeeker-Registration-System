import 'field_metadata.dart';

class ExperienceEntry {
  String title;
  String employer;
  String location;
  String startDate;
  String endDate;
  String description;
  int pageIndex;
  FieldMetadata metadata;

  ExperienceEntry({
    this.title = '',
    this.employer = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.description = '',
    this.pageIndex = 0,
    FieldMetadata? metadata,
  }) : metadata = metadata ?? FieldMetadata.defaultMeta;

  ExperienceEntry copyWith({
    String? title,
    String? employer,
    String? location,
    String? startDate,
    String? endDate,
    String? description,
    int? pageIndex,
    FieldMetadata? metadata,
  }) =>
      ExperienceEntry(
        title: title ?? this.title,
        employer: employer ?? this.employer,
        location: location ?? this.location,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        description: description ?? this.description,
        pageIndex: pageIndex ?? this.pageIndex,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'employer': employer,
        'location': location,
        'start_date': startDate,
        'end_date': endDate,
        'description': description,
        'page_index': pageIndex,
        'metadata': metadata.toJson(),
      };

  factory ExperienceEntry.fromJson(Map<String, dynamic> j) => ExperienceEntry(
        title: j['title'] as String? ?? '',
        employer: j['employer'] as String? ?? '',
        location: j['location'] as String? ?? '',
        startDate: j['start_date'] as String? ?? '',
        endDate: j['end_date'] as String? ?? '',
        description: j['description'] as String? ?? '',
        pageIndex: j['page_index'] as int? ?? 0,
        metadata: FieldMetadata.fromJson(
            j['metadata'] as Map<String, dynamic>? ?? {}),
      );

  @override
  String toString() =>
      '$title at $employer${location.isNotEmpty ? ", $location" : ""} ($startDate${endDate.isNotEmpty ? "–$endDate" : ""})';
}
