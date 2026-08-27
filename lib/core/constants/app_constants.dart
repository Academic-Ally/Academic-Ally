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

  // Cloud Functions base URL
  static const String cloudFunctionsBaseUrl =
      'https://us-central1-academic-ally-app.cloudfunctions.net';

  // Python AI backend base URL (FastAPI + CrewAI — see backend/README.md).
  //
  // For local development, swap this for:
  //   'http://10.0.2.2:8000'   Android emulator (NAT alias for the host's 127.0.0.1)
  //   'http://localhost:8000'  iOS simulator or `flutter run -d windows`
  //   'http://<host-LAN-IP>:8000'  physical device on the same Wi-Fi
  //                                (bind uvicorn with --host 0.0.0.0)
  static const String aiBackendBaseUrl =
      'https://academic-ally-production.up.railway.app';

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
