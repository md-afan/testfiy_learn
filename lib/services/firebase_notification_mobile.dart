import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseNotification {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Testify Learn Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('🔁 Android Notification clicked: ${message.data}');
    });
  }

  static Future<void> subscribeToQuizTopics(
      String quizId, bool isTeacher) async {
    final role = isTeacher ? 'teacher' : 'students';
    final types = ['1d', '1h', '10m', 'live', 'insufficient_enrollment'];
    for (final t in types) {
      final topic = 'quiz_${quizId}_${t}_$role';
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to $topic');
    }
    await _messaging.unsubscribeFromTopic('quiz_${quizId}_$role');
  }

  static Future<void> unSubscribeToQuizTopics(
      String quizId, bool isTeacher) async {
    final role = isTeacher ? 'teacher' : 'students';
    final types = ['1d', '1h', '10m', 'live','insufficient_enrollment'];
    for (final t in types) {
      final topic = 'quiz_${quizId}_${t}_$role';
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Subscribed to $topic');
    }
    await _messaging.unsubscribeFromTopic('quiz_${quizId}_$role');
  }

  /// Save FCM token to Firestore for push-to-token fallback
  static Future<void> saveTokenToFirestore(
      String userId, bool isTeacher) async {
    final token = await getToken();
    if (token == null) return;
    final collection = isTeacher ? 'teachers' : 'students';
    await FirebaseFirestore.instance.collection(collection).doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Remove token on logout
  static Future<void> removeTokenFromFirestore(
      String userId, bool isTeacher) async {
    final token = await getToken();
    if (token == null) return;
    final collection = isTeacher ? 'teachers' : 'students';
    await FirebaseFirestore.instance.collection(collection).doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> subscribeToCoaching(String coachingCode, bool isTeacher) async {
  try {
    final messaging = FirebaseMessaging.instance;
    String topic =
        isTeacher ? '${coachingCode}_teacher' : '${coachingCode}_students';
    await messaging.subscribeToTopic(topic);
  } catch (e) {
    print(' Error subscribing to coaching topics: $e');
  }
}

static Future<void> unSubscribeToCoaching(String coachingCode, bool isTeacher) async {
  try {
    final messaging = FirebaseMessaging.instance;
    String topic =
        isTeacher ? '${coachingCode}_teacher' : '${coachingCode}_students';
    await messaging.unsubscribeFromTopic(topic);
  } catch (e) {
    print(' Error subscribing to coaching topics: $e');
  }
}
}


