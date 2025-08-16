import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachingDetailsProvider extends ChangeNotifier {
  final String coachingCode;

  CoachingDetailsProvider({required this.coachingCode}) {
    fetchData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _coachingData;
  Map<String, dynamic>? get coachingData => _coachingData;

  Map<String, dynamic>? _teacherData;
  Map<String, dynamic>? get teacherData => _teacherData;

  int _studentsCount = 0;
  int get studentsCount => _studentsCount;

  int _teachersCount = 0;
  int get teachersCount => _teachersCount;

  int _testsCount = 0;
  int get testsCount => _testsCount;

  String? _error;
  String? get error => _error;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final coachingDoc =
          await _firestore.collection('coachingCodes').doc(coachingCode).get();

      if (!coachingDoc.exists) {
        _error = "Coaching data not found.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      _coachingData = coachingDoc.data();

      final teacherId = _coachingData?['createdBy'];

      if (teacherId != null) {
        final teacherDoc =
            await _firestore.collection('teachers').doc(teacherId).get();
        _teacherData = teacherDoc.data();
      } else {
        _teacherData = null;
      }

      final studentsCountQuery = await _firestore
          .collection('coachingCodes')
          .doc(coachingCode)
          .collection('students')
          .count()
          .get();
      _studentsCount = studentsCountQuery.count!;

      final teachersCountQuery = await _firestore
          .collection('coachingCodes')
          .doc(coachingCode)
          .collection('teachers')
          .count()
          .get();
      _teachersCount = teachersCountQuery.count!;

      final testsCountQuery = await _firestore
          .collection('quizzes')
          .where("coachingCode", isEqualTo: coachingCode)
          .count()
          .get();
      _testsCount = testsCountQuery.count!;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchData();
  }
}
