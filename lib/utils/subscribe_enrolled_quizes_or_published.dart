import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_notification.dart';

Future<void> subscribeToAllQuizTopics(String uid, bool isTeacher) async {
  try {
    final firestore = FirebaseFirestore.instance;

    if (!isTeacher) {
      final enrolledSnapshot = await firestore
          .collection('students')
          .doc(uid)
          .collection('enrolledQuizzes')
          .get();

      for (var doc in enrolledSnapshot.docs) {
        final quizId = doc.id;
        // susbscrib the topics to all enrolled tests or quizzes
        await FirebaseNotification.subscribeToQuizTopics(quizId, isTeacher);
      }
    }

    if (isTeacher) {
      final publishedSnapshot = await firestore
          .collection('quizzes')
          .where('createdBy', isEqualTo: uid)
          .where('isPublished', isEqualTo: true)
          .get();

      for (var doc in publishedSnapshot.docs) {
        final quizId = doc.id;
        // susbscrib the topics to all enrolled tests or quizzes
        await FirebaseNotification.subscribeToQuizTopics(quizId, isTeacher);
      }
    }
  } catch (e) {
    print('❌ Error subscribing to quiz topics: $e');
  }
}

Future<void> unSubscribeToAllQuizTopics(String uid, bool isTeacher) async {
  try {
    final firestore = FirebaseFirestore.instance;

    if (!isTeacher) {
      final enrolledSnapshot = await firestore
          .collection('students')
          .doc(uid)
          .collection('enrolledQuizzes')
          .get();

      for (var doc in enrolledSnapshot.docs) {
        final quizId = doc.id;
        // susbscrib the topics to all enrolled tests or quizzes
        await FirebaseNotification.unSubscribeToQuizTopics(quizId, isTeacher);
      }
    }

    if (isTeacher) {
      final publishedSnapshot = await firestore
          .collection('quizzes')
          .where('createdBy', isEqualTo: uid)
          .where('isPublished', isEqualTo: true)
          .get();

      for (var doc in publishedSnapshot.docs) {
        final quizId = doc.id;
        // susbscrib the topics to all enrolled tests or quizzes
        await FirebaseNotification.subscribeToQuizTopics(quizId, isTeacher);
      }
    }
  } catch (e) {
    print('❌ Error subscribing to quiz topics: $e');
  }
}
