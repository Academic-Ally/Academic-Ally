/// Centralized Firestore collection/document path helpers.
class FirestorePaths {
  // Users
  static String users() => 'Users';
  static String user(String uid) => 'Users/$uid';
  static String userBookmarks(String uid) => 'Users/$uid/NotesBookmarked';
  static String userBookmark(String uid, String noteId) =>
      'Users/$uid/NotesBookmarked/$noteId';
  static String userUploads(String uid) => 'Users/$uid/UserUploads';
  static String userUpload(String uid, String uploadId) =>
      'Users/$uid/UserUploads/$uploadId';
  static String userRatedList(String uid) => 'Users/$uid/RatedList';
  static String userInitializedPdfs(String uid) =>
      'Users/$uid/InitializedPdf';
  static String userInitializedPdf(String uid, String docId) =>
      'Users/$uid/InitializedPdf/$docId';
  static String userSeekHubRequests(String uid) =>
      'Users/$uid/SeekHub/Requests';

  // Universities → Resources
  static String universityBase(
    String university,
    String course,
    String branch,
    String sem,
  ) =>
      'Universities/$university/$course/$branch/$sem';

  static String subjectsList(
    String university,
    String course,
    String branch,
    String sem,
  ) =>
      'Universities/$university/$course/$branch/$sem/SubjectsList';

  static String resources(
    String university,
    String course,
    String branch,
    String sem,
    String resourceType,
    String subject,
  ) =>
      'Universities/$university/$course/$branch/$sem/$resourceType/$subject';

  // QueryList (for search/recommendations)
  static String queryList(String university, String course) =>
      'QueryList/$university/$course/SubjectsListDetail';

  // SeekHub
  static String seekHub(String university, String course) =>
      'SeekHub/$university/$course';
  static String seekHubRequest(
    String university,
    String course,
    String requestId,
  ) =>
      'SeekHub/$university/$course/$requestId';

  // NewUploads
  static String newUploads(
    String university,
    String course,
    String branch,
  ) =>
      'NewUploads/$university/$course/$branch/uploads';

  // Utils
  static String utilsMetadata() => 'utils/meta-data';
  static String utilsProtectedMetadata() => 'UtilsProtected/meta-data';

  // Immutable user data
  static String immutableUserData(String uid) => 'ImmutableUserData/$uid';

  // Premium users
  static String premiumUser(String userId) => 'Premium_Users/$userId';

  // User reports (abuse reporting)
  static String userReport(
    String university,
    String course,
    String branch,
    String sem,
    String uid,
  ) =>
      'userReports/$university/$course/$branch/$sem/$uid';

  // Misconception Graph / Mastery (per-user, Phase 2)
  static String userMisconceptions(String uid) =>
      'Users/$uid/Misconceptions';
  static String userMisconception(String uid, String nodeId) =>
      'Users/$uid/Misconceptions/$nodeId';
  static String userMasteryScores(String uid) =>
      'Users/$uid/MasteryScores';
  static String userMasteryScore(String uid, String nodeId) =>
      'Users/$uid/MasteryScores/$nodeId';

  // Study Planner (per-user, Phase 2)
  static String userStudyPlans(String uid) => 'Users/$uid/StudyPlans';
  static String userStudyPlan(String uid, String planId) =>
      'Users/$uid/StudyPlans/$planId';

  // PYQ Analysis (shared across users, Phase 2)
  static String pyqAnalysis(
    String university,
    String course,
    String branch,
    String sem,
    String subject,
  ) =>
      'PyqAnalysis/$university/$course/$branch/$sem/$subject';

  // Doubt history (per-user, Phase 2)
  static String userDoubtHistory(String uid) => 'Users/$uid/DoubtHistory';
  static String userDoubt(String uid, String doubtId) =>
      'Users/$uid/DoubtHistory/$doubtId';

  // Project Copilot (per-user, Phase 2)
  static String userProjects(String uid) => 'Users/$uid/Projects';
  static String userProject(String uid, String projectId) =>
      'Users/$uid/Projects/$projectId';

  // Jobs (shared, Phase 3)
  static String jobs() => 'Jobs';
  static String job(String jobId) => 'Jobs/$jobId';

  // Channels + Messages (shared, Phase 3)
  static String channels() => 'Channels';
  static String channel(String channelId) => 'Channels/$channelId';
  static String channelMessages(String channelId) =>
      'Channels/$channelId/Messages';
  static String channelMessage(String channelId, String messageId) =>
      'Channels/$channelId/Messages/$messageId';

  // Knowledge Graph (admin-curated topic nodes, Phase 2 design)
  static String knowledgeGraphNodes(
    String university,
    String course,
    String subject,
  ) =>
      'KnowledgeGraph/$university/$course/$subject/nodes';
  static String knowledgeGraphNode(
    String university,
    String course,
    String subject,
    String nodeId,
  ) =>
      'KnowledgeGraph/$university/$course/$subject/nodes/$nodeId';

  // Notification topic format
  static String notificationTopic(
    String university,
    String course,
    String branch,
    String sem,
  ) =>
      '${university}_${course}_${branch}_$sem';
}
