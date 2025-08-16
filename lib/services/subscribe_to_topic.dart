



// Future<void> unsubscribeFromQuizTopics({
//   required String quizId,
//   required String role, // 'student' or 'teacher'
// }) async {
//   final List<String> timeTypes = ['1d', '1h', '10m', 'live'];
//   for (final time in timeTypes) {
//     final topic = "quiz_${quizId}_${time}_${role}";
//     await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
//     print("Unsubscribed from: $topic");
//   }
// }
