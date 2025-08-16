export 'firebase_notification_stub.dart'
  if (dart.library.html) 'firebase_notification_web.dart'
  if (dart.library.io) 'firebase_notification_mobile.dart';
