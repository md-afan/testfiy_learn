import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/secure_locally_storage.dart';
import '../../utils/enryped_decryped.dart';

class NotificationProvider with ChangeNotifier {
  String? _role;
  String? _userId;
  String get userId => _userId ?? '';
  String get role => _role ?? '';

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  final List<String> _filters = [
    'All',
    'quiz_reminder',
    'attendance_reminder',
    'result',
    'leaderboard',
  ];
  List<String> get filters => _filters;

  List<DocumentSnapshot> _olderNotifications = [];
  List<DocumentSnapshot> get olderNotifications => _olderNotifications;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  NotificationProvider() {
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await LocalStorage.getLocalStorage("uid");
    final encryptedRole = await LocalStorage.getLocalStorage("role");
    final decriptedRole = await EncryptionHelper.decrypt(encryptedRole!);
    _role = decriptedRole == "student" ? "students" : "teachers";
    _userId = id;
    notifyListeners();
  }

  // Stream for real-time notifications
  Stream<QuerySnapshot> get realTimeNotifications {
    if (_userId == null && _role == null) {
      return const Stream.empty();
    }

    Query query = FirebaseFirestore.instance
        .collection(_role!)
        .doc(_userId!)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (_selectedFilter != 'All') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }
    return query.snapshots();
  }

  // Load more older notifications
  Future<void> loadMoreNotifications(String role) async {
    if (_userId == null || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    Query query = FirebaseFirestore.instance
        .collection(role)
        .doc(_userId!)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }
    if (_selectedFilter != 'All') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      _olderNotifications.addAll(snapshot.docs);
    } else {
      _hasMore = false;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void changeFilter(String filter) {
    _selectedFilter = filter;
    _olderNotifications.clear();
    _lastDoc = null;
    _hasMore = true;
    notifyListeners();
  }

  Future<void> deleteNotification(DocumentSnapshot doc) async {
    await doc.reference.delete();
    _olderNotifications.remove(doc);
    notifyListeners();
  }

  Future<void> markAsRead(DocumentSnapshot doc) async {
    await doc.reference.update({'read': true});
  }

  String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays} days ago";
  }

  /// 🔥 Fetch sender profile image based on senderType
  Future<String?> getSenderImage(String senderId, String senderType) async {
    print('$senderId $senderType');

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(senderType)
          .doc(senderId)
          .get();
      print(doc.data());

      if (!doc.exists) return null;

      switch (senderType) {
        case "teachers":
          return doc["teacherImageUrl"];
        case "students":
          return doc["profileImageUrl"];
        case "coachingCodes":
          return doc["logoUrl"];
        default:
          return null;
      }
    } catch (e) {
      debugPrint("Error fetching sender image: $e");
      return null;
    }
  }

  String capitalize(String str) =>
      str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : str;
}
