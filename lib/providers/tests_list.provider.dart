// import 'package:flutter/foundation.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class TestListProvider with ChangeNotifier {
//   final String coachingCode;
//   final String uid;

//   TestListProvider({
//     required this.coachingCode,
//     required this.uid,
//   }) {
//     _init();
//   }

//   // State variables
//   List<Quiz> _quizzes = [];
//   bool _isLoading = false;
//   bool _hasMore = true;
//   DocumentSnapshot? _lastDocument;
//   bool _isRefreshing = false;
//   String? _error;
//   bool _initialLoadComplete = false;

//   // Getters
//   List<Quiz> get quizzes => _quizzes;
//   bool get isLoading => _isLoading;
//   bool get hasMore => _hasMore;
//   bool get isRefreshing => _isRefreshing;
//   String? get error => _error;
//   bool get initialLoadComplete => _initialLoadComplete;

//   Future<void> _init() async {
//     await fetchQuizzes();
//     _initialLoadComplete = true;
//   }

//   Future<void> fetchQuizzes({bool isRefresh = false}) async {
//     if ((_isLoading && !isRefresh) || (!isRefresh && !_hasMore)) return;

//     if (isRefresh) {
//       _isRefreshing = true;
//       _lastDocument = null;
//       _hasMore = true;
//       _quizzes = [];
//     } else {
//       _isLoading = true;
//     }

//     _error = null;
//     notifyListeners();

//     try {
//       Query query = FirebaseFirestore.instance
//           .collection('quizzes')
//           .where('coachingCode', isEqualTo: coachingCode)
//           .where('isPublished', isEqualTo: true)
//           .orderBy('testDateTime', descending: filter == 'completed')
//           .limit(10);

//       if (_lastDocument != null && !isRefresh) {
//         query = query.startAfterDocument(_lastDocument!);
//       }

//       final snapshot = await query.get(
//         const GetOptions(
//           source: Source.serverAndCache,
//         ),
//       );

//       if (snapshot.docs.isEmpty) {
//         _hasMore = false;
//       } else {
//         _lastDocument = snapshot.docs.last;
//         final newQuizzes = await _fetchWithEnrollmentStatus(snapshot.docs);

//         if (isRefresh) {
//           _quizzes = newQuizzes;
//         } else {
//           // Avoid duplicates
//           final newIds = newQuizzes.map((q) => q.id).toSet();
//           _quizzes.removeWhere((q) => newIds.contains(q.id));
//           _quizzes.addAll(newQuizzes);
//         }

//         _filterQuizzes();
//       }
//     } catch (e) {
//       _error = 'Failed to load quizzes: ${e.toString()}';
//       debugPrint('Error fetching quizzes: $e');
//     } finally {
//       _isLoading = false;
//       _isRefreshing = false;
//       notifyListeners();
//     }
//   }

//   Future<List<Quiz>> _fetchWithEnrollmentStatus(List<DocumentSnapshot> docs) async {
//     final List<Quiz> result = [];
//     final batch = FirebaseFirestore.instance.batch();

//     // Prepare all batch reads
//     for (var doc in docs) {
//       final ref = FirebaseFirestore.instance
//           .collection('quizzes')
//           .doc(doc.id)
//           .collection('enrolledStudents')
//           .doc(uid);
//       batch.get(ref);
//     }

//     // Execute all reads in a single batch
//     final snapshots = await batch.commit();

//     for (int i = 0; i < docs.length; i++) {
//       final doc = docs[i];
//       final enrollmentData = snapshots.results[i];
//       result.add(Quiz.fromFirestore(doc, enrollmentData.exists));
//     }

//     return result;
//   }

//   void _filterQuizzes() {
//     final now = DateTime.now();
//     _quizzes = _quizzes.where((quiz) {
//       if (quiz.testDateTime == null) return false;

//       final isCompleted = quiz.testDateTime!.isBefore(now);
//       final isUpcoming = quiz.testDateTime!.isAfter(now);
//       final isLive = quiz.status == 'live';
//       final isLivePending = quiz.status == 'live_pending';

//       switch (filter) {
//         case 'enrolled':
//           return quiz.isEnrolled && !isCompleted && !isLive;
//         case 'completed':
//           return isCompleted || (quiz.status == 'completed');
//         case 'upcoming':
//           return (isUpcoming && !quiz.isEnrolled) || 
//                  (isLivePending && !quiz.isEnrolled);
//         default:
//           return true;
//       }
//     }).toList();
//   }

//   Future<void> refresh() async {
//     await fetchQuizzes(isRefresh: true);
//   }

//   void updateEnrollmentStatus(String quizId, bool isEnrolled) {
//     final index = _quizzes.indexWhere((q) => q.id == quizId);
//     if (index != -1) {
//       _quizzes[index] = _quizzes[index].copyWith(isEnrolled: isEnrolled);
//       _filterQuizzes();
//       notifyListeners();
//     }
//   }
// }

// extension QuizCopyWith on Quiz {
//   Quiz copyWith({
//     String? id,
//     String? title,
//     DateTime? testDateTime,
//     DateTime? createdAt,
//     String? status,
//     bool? isPublished,
//     bool? isEnrolled,
//     String? coachingCode,
//   }) {
//     return Quiz(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       testDateTime: testDateTime ?? this.testDateTime,
//       createdAt: createdAt ?? this.createdAt,
//       status: status ?? this.status,
//       isPublished: isPublished ?? this.isPublished,
//       isEnrolled: isEnrolled ?? this.isEnrolled,
//       coachingCode: coachingCode ?? this.coachingCode,
//     );
//   }
// }