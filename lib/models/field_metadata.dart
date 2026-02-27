/// Metadata attached to every extracted field.
class FieldMetadata {
  final double confidence;
  final dynamic sourcePage; // int or List<int>
  final String rawSnippet;
  final String extractionMethod;

  const FieldMetadata({
    required this.confidence,
    required this.sourcePage,
    this.rawSnippet = '',
    this.extractionMethod = 'heuristic',
  });

  Map<String, dynamic> toJson() => {
        'confidence': confidence,
        'source_page': sourcePage,
        'raw_snippet': rawSnippet,
        'extraction_method': extractionMethod,
      };

  factory FieldMetadata.fromJson(Map<String, dynamic> j) => FieldMetadata(
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
        sourcePage: j['source_page'],
        rawSnippet: j['raw_snippet'] as String? ?? '',
        extractionMethod: j['extraction_method'] as String? ?? 'heuristic',
      );

  static FieldMetadata get defaultMeta => const FieldMetadata(
      confidence: 0.6,
      sourcePage: 0,
      rawSnippet: '',
      extractionMethod: 'heuristic');
}

/// A field value paired with its extraction metadata.
class FieldValue<T> {
  T value;
  FieldMetadata metadata;

  FieldValue({required this.value, required this.metadata});

  Map<String, dynamic> toJson(dynamic Function(T) serialize) => {
        'value': serialize(value),
        'metadata': metadata.toJson(),
      };

  static FieldValue<String> fromJsonString(Map<String, dynamic> j) =>
      FieldValue<String>(
        value: j['value'] as String? ?? '',
        metadata: FieldMetadata.fromJson(
            j['metadata'] as Map<String, dynamic>? ?? {}),
      );
}

/// A contact-type field (phone, email, URL) with a label.
class ContactField {
  String value;
  String label; // mobile, home, work, primary, etc.
  FieldMetadata metadata;

  ContactField({required this.value, this.label = '', required this.metadata});

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'metadata': metadata.toJson(),
      };

  factory ContactField.fromJson(Map<String, dynamic> j) => ContactField(
        value: j['value'] as String? ?? '',
        label: j['label'] as String? ?? '',
        metadata: FieldMetadata.fromJson(
            j['metadata'] as Map<String, dynamic>? ?? {}),
      );
}

/// Raw text for a single OCR page.
class PageText {
  final int pageIndex;
  final String text;

  const PageText({required this.pageIndex, required this.text});

  Map<String, dynamic> toJson() => {'page_index': pageIndex, 'text': text};

  factory PageText.fromJson(Map<String, dynamic> j) => PageText(
      pageIndex: j['page_index'] as int? ?? 0,
      text: j['text'] as String? ?? '');
}
