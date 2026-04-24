class AppConstants {
  // App info
  static const String appName = 'Academic Ally';
  static const String packageName = 'com.academically';

  // Universities
  static const String jntuh = 'JNTUH';
  static const String ou = 'OU';

  // Courses
  static const String btech = 'BTECH';
  static const String be = 'BE';

  // Branches
  static const List<String> branches = [
    'CSE',
    'IT',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
  ];

  // Semesters
  static const List<String> semesters = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];

  // Resource types
  static const String notes = 'Notes';
  static const String questionPapers = 'QuestionPapers';
  static const String otherResources = 'OtherResources';
  static const String syllabus = 'Syllabus';

  static const List<String> resourceTypes = [
    notes,
    questionPapers,
    otherResources,
    syllabus,
  ];

  // Cloudflare R2 config (to be filled later)
  static const String r2Endpoint = '';
  static const String r2BucketName = 'academic-ally';

  // Cloud Functions base URL
  static const String cloudFunctionsBaseUrl =
      'https://us-central1-academic-ally-app.cloudfunctions.net';

  // Python AI backend base URL (Firebase Functions Gen 2 / us-central1)
  // Each AI endpoint is a top-level function under this origin, e.g.
  //   POST {aiBackendBaseUrl}/pyq_analyze
  static const String aiBackendBaseUrl =
      'https://us-central1-academic-ally-app.cloudfunctions.net';

  // Chat limits
  static const int maxChatInitiations = 50;
  static const int dailyMessageLimitRegular = 10;
  static const int dailyMessageLimitPremium = 15;

  // Deep link config
  static const String deepLinkScheme = 'academically';
  static const String deepLinkHost = 'app.getacademically.co';

  // Local storage keys
  static const String themeKey = 'theme_mode';
  static const String introShownKey = 'intro_shown';
  static const String recentPdfsKey = 'recent_pdfs';
}
