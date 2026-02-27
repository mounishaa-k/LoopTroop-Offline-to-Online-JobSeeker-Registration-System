class AppConstants {
  // Auth (local hardcoded)
  static const String defaultUsername = 'admin';
  static const String defaultPassword = 'password123';

  // Confidence thresholds
  static const double highConfidenceThreshold = 0.80;
  static const double mediumConfidenceThreshold = 0.55;

  // Extraction method labels
  static const String methodRegex = 'regex';
  static const String methodKeyword = 'keyword';
  static const String methodHeuristic = 'heuristic';
  static const String methodNER = 'NER';

  // QR max size (chars)
  static const int qrMaxPayloadChars = 800;

  // Database
  static const String dbName = 'fairtrack.db';
  static const String tableRecords = 'records';

  // App info
  static const String appName = 'FairTrack';
  static const String appSubtitle = 'Job Fair Registration';
  static const String extractionVersion = 'v1';

  // Section heading keywords (for extraction pipeline)
  static const List<String> educationKeywords = [
    'education',
    'academic',
    'qualifications',
    'academics',
    'educational background',
    'academic background',
    'studies',
    'academic qualifications',
    'academic history',
    'educational qualifications',
  ];
  static const List<String> experienceKeywords = [
    'experience',
    'work experience',
    'employment',
    'professional experience',
    'career history',
    'employment history',
    'work history',
    'career background',
    'professional background',
    'professional history',
    'career',
  ];
  static const List<String> skillsKeywords = [
    'skills',
    'technical skills',
    'competencies',
    'expertise',
    'technologies',
    'key skills',
    'core skills',
    'technical competencies',
    'skill set',
    'technical expertise',
    'proficiencies',
    'areas of expertise',
  ];
  static const List<String> languagesKeywords = [
    'languages',
    'language proficiency',
    'language skills',
    'spoken languages',
    'linguistic skills',
  ];
  static const List<String> certificationsKeywords = [
    'certifications',
    'certificates',
    'licenses',
    'accreditations',
    'professional certifications',
    'credentials',
    'professional credentials',
  ];
  static const List<String> projectsKeywords = [
    'projects',
    'personal projects',
    'notable projects',
    'key projects',
    'portfolio',
    'academic projects',
  ];
  static const List<String> summaryKeywords = [
    'summary',
    'objective',
    'profile',
    'about me',
    'professional summary',
    'career objective',
    'personal statement',
    'executive summary',
    'professional profile',
    'overview',
    'about',
  ];
  static const List<String> achievementsKeywords = [
    'achievements',
    'awards',
    'honors',
    'accomplishments',
    'recognition',
    'honours',
    'accolades',
  ];
  static const List<String> referencesKeywords = [
    'references',
    'referees',
    'reference',
  ];

  // Degree keywords
  static const List<String> degreeKeywords = [
    'phd',
    'ph.d',
    'doctor',
    'doctorate',
    'master',
    'm.s.',
    'm.sc',
    'msc',
    'mba',
    'm.eng',
    'bachelor',
    'b.s.',
    'b.sc',
    'bsc',
    'b.a.',
    'b.eng',
    'b.tech',
    'associate',
    'diploma',
    'certificate',
    'hnd',
    'ond',
    'advanced diploma',
    'honours',
    'honors',
  ];
}
