import 'dart:convert';
import 'extraction_result.dart';
import 'field_metadata.dart';

class ResumeRecord {
  final String id;
  final String displayId;
  String rawText;
  List<PageText> pagesTexts;
  List<String> images; // file paths
  ExtractionResult extracted;
  Map<String, dynamic> extractionMetadata;
  String status; // 'pending' | 'synced'
  final DateTime createdAt;
  DateTime updatedAt;

  ResumeRecord({
    required this.id,
    String? displayId,
    this.rawText = '',
    List<PageText>? pagesTexts,
    List<String>? images,
    ExtractionResult? extracted,
    Map<String, dynamic>? extractionMetadata,
    this.status = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : displayId = displayId ?? id,
        pagesTexts = pagesTexts ?? [],
        images = images ?? [],
        extracted = extracted ?? ExtractionResult(),
        extractionMetadata = extractionMetadata ?? {'extraction_version': 'v1'},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get candidateName => extracted.fullName?.value.isNotEmpty == true
      ? extracted.fullName!.value
      : 'Unnamed Candidate';

  String get primaryPhone =>
      extracted.phones.isNotEmpty ? extracted.phones.first.value : '';

  String get primaryEmail =>
      extracted.emails.isNotEmpty ? extracted.emails.first.value : '';

  bool get isPending => status == 'pending';
  bool get isSynced => status == 'synced';

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_id': displayId,
        'raw_text': rawText,
        'pages_texts': pagesTexts.map((e) => e.toJson()).toList(),
        'images': images,
        'extracted': extracted.toJson(),
        'extraction_metadata': extractionMetadata,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ResumeRecord.fromJson(Map<String, dynamic> j) => ResumeRecord(
        id: j['id'] as String,
        displayId: j['display_id'] as String?,
        rawText: j['raw_text'] as String? ?? '',
        pagesTexts: (j['pages_texts'] as List? ?? [])
            .map((e) => PageText.fromJson(e as Map<String, dynamic>))
            .toList(),
        images: List<String>.from(j['images'] as List? ?? []),
        extracted: ExtractionResult.fromJson(
            j['extracted'] as Map<String, dynamic>? ?? {}),
        extractionMetadata: j['extraction_metadata'] as Map<String, dynamic>? ??
            {'extraction_version': 'v1'},
        status: j['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(j['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

  String toJsonString() => jsonEncode(toJson());

  static ResumeRecord fromJsonString(String s) =>
      ResumeRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
