import 'dart:html' as html;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseNotification {
  static final _messaging = FirebaseMessaging.instance;
  static final _firebaseFunction = FirebaseFunctions.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize FCM and local notifications for Flutter Web
  static Future<void> init() async {
    try {
      // Register service worker (required for web push)
      await html.window.navigator.serviceWorker
          ?.register('firebase-messaging-sw.js');

      // Initialize local notifications plugin
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Request notification permissions
      final permission = await _messaging.requestPermission();
      if (permission.authorizationStatus != AuthorizationStatus.authorized) {
        print("❌ Notification permission not granted.");
        return;
      }

      // Listen for foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final title = message.notification?.title ?? "Notification";
        final body = message.notification?.body ?? "";

        await _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'quiz_channel', // Unique channel ID
              'Quiz Notifications', // Channel name
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload:
              message.data['quizId'], // Optional payload for handling clicks
        );
      });

      // Handle notification click
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print("🔁 Web Notification Clicked: ${message.data}");
        // TODO: Navigate or handle click based on message.data
      });
    } catch (e) {
      print("❌ Error initializing web notifications: $e");
    }
  }

  /// Save FCM token to Firestore
  static Future<void> saveTokenToFirestore(
      String userId, bool isTeacher) async {
    final token = await _messaging.getToken(
      vapidKey:
          "BIRujnEn3IvdiMrpd6pDn-uhM8TZjybaWbpb39Edte4p66TCtrWvVWsqgvfJqPQW3kmSpWJjxaJpF2eIsHN_wo4",
    );
    if (token == null) return;
    final collection = isTeacher ? "teachers" : "students";
    await FirebaseFirestore.instance.collection(collection).doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token])
    }, SetOptions(merge: true));
  }

  static Future<void> subscribeToQuizTopics(
      String quizId, bool isTeacher) async {
    final token = await _messaging.getToken(
      vapidKey:
          "BIRujnEn3IvdiMrpd6pDn-uhM8TZjybaWbpb39Edte4p66TCtrWvVWsqgvfJqPQW3kmSpWJjxaJpF2eIsHN_wo4",
    );
    final role = isTeacher ? 'teacher' : 'students';
    final types = ['1d', '1h', '10m', 'live','insufficient_enrollment'];
    for (final t in types) {
      final topic = 'quiz_${quizId}_${t}_$role';
      await _firebaseFunction
          .httpsCallable('subscribeToWeb')
          .call({'token': token, 'topic': topic});
      print('✅ Subscribed to $topic');
    }
      await _firebaseFunction
          .httpsCallable('unsubscribeToWeb')
          .call({'token': token, 'topic': 'quiz_${quizId}_$role'});
  }

  static Future<void> unSubscribeToQuizTopics(
      String quizId, bool isTeacher) async {
    final token = await _messaging.getToken(
      vapidKey:
          "BIRujnEn3IvdiMrpd6pDn-uhM8TZjybaWbpb39Edte4p66TCtrWvVWsqgvfJqPQW3kmSpWJjxaJpF2eIsHN_wo4",
    );
    final role = isTeacher ? 'teacher' : 'students';
    final types = ['1d', '1h', '10m', 'live', 'insufficient_enrollment'];
    for (final t in types) {
      final topic = 'quiz_${quizId}_${t}_$role';
      await _firebaseFunction
          .httpsCallable('unsubscribeToWeb')
          .call({'token': token, 'topic': topic});
    }
     await _firebaseFunction
          .httpsCallable('unsubscribeToWeb')
          .call({'token': token, 'topic': 'quiz_${quizId}_$role'});
  }

  /// Remove FCM token from Firestore on logout
  static Future<void> removeTokenFromFirestore(
      String userId, bool isTeacher) async {
    final token = await _messaging.getToken(
      vapidKey:
          "BIRujnEn3IvdiMrpd6pDn-uhM8TZjybaWbpb39Edte4p66TCtrWvVWsqgvfJqPQW3kmSpWJjxaJpF2eIsHN_wo4",
    );
    if (token == null) return;
    final collection = isTeacher ? "teachers" : "students";
    await FirebaseFirestore.instance.collection(collection).doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token])
    });
  }

  /// Optional: Get FCM token for debugging
  static Future<String?> getToken() async {
    return await _messaging.getToken(
      vapidKey:
          "BIRujnEn3IvdiMrpd6pDn-uhM8TZjybaWbpb39Edte4p66TCtrWvVWsqgvfJqPQW3kmSpWJjxaJpF2eIsHN_wo4",
    );
  }

  static Future<void> subscribeToCoaching(
      String coachingCode, bool isTeacher) async {
    try {
      final token = await _messaging.getToken(
        vapidKey:
            "BIRujnEn3IvdiMrpd6pDn-uhM8TZjybaWbpb39Edte4p66TCtrWvVWsqgvfJqPQW3kmSpWJjxaJpF2eIsHN_wo4",
      );
      String topic =
          isTeacher ? '${coachingCode}_teacher' : '${coachingCode}_students';
      await _firebaseFunction
          .httpsCallable('subscribeToWeb')
          .call({'token': token, 'topic': topic});
    } catch (e) {
      print(' Error subscribing to coaching topics: $e');
    }
  }

  static Future<void> unSubscribeToCoaching(
      String coachingCode, bool isTeacher) async {
    try {
      final token = await _messaging.getToken(
        vapidKey:
            "BIRujnEn3IvdiMrpd6pDn-uhM8TZjybaWbpb39Edte4p66TCtrWvVWsqgvfJqPQW3kmSpWJjxaJpF2eIsHN_wo4",
      );
      String topic =
          isTeacher ? '${coachingCode}_teacher' : '${coachingCode}_students';
      await _firebaseFunction
          .httpsCallable('unsubscribeToWeb')
          .call({'token': token, 'topic': topic});
    } catch (e) {
      print(' Error subscribing to coaching topics: $e');
    }
  }
}
