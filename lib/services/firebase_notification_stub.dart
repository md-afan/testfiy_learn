class FirebaseNotification {
  static Future<void> init() async {}
  static Future<void> saveTokenToFirestore(
      String userId, bool isTeacher) async {}
  static Future<String?> getToken() async => null;
  static Future<void> subscribeToQuizTopics(
      String quizId, bool isTeacher) async {}
  static Future<void> unSubscribeToQuizTopics(
      String quizId, bool isTeache) async {}

  static Future<void> removeTokenFromFirestore(
      String uid, bool isTeacher) async {}
  static Future<void> unSubscribeToCoaching(
      String coachingCode, bool isTeacher) async {}

  static Future<void> subscribeToCoaching(
      String coachingCode, bool isTeacher) async {}
}
