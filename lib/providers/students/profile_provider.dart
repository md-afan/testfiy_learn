import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/students/profile_modal.dart';

class StudentProfileProvider with ChangeNotifier {
  StudentModel? _student;
  String error = "";
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StudentModel? get student => _student;
  bool get isLoading => _isLoading;

  // Fetch once (Firebase cache first)
  Future<void> fetchStudentProfile(String uid) async {
    if (_student != null) return; // Already cached
    _isLoading = true;
    error = "";
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('students')
          .doc(uid)
          .get(const GetOptions(source: Source.cache)); // Try cache first

      if (doc.exists) {
        _student = StudentModel.fromMap(doc.data()!);
      } else {
        // If not in cache, fetch from server
        final serverDoc = await _firestore
            .collection('students')
            .doc(uid)
            .get(const GetOptions(source: Source.server));
        if (serverDoc.exists) {
          _student = StudentModel.fromMap(serverDoc.data()!);
        }
      }
    } catch (e) {
      error = "Error fetching profile";
      debugPrint('Error fetching profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Refresh (Force server fetch)
  Future<void> refreshStudentProfile(String uid) async {
    _isLoading = true;
    error = "";
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('students')
          .doc(uid)
          .get(const GetOptions(source: Source.server)); // Force server

      if (doc.exists) {
        _student = StudentModel.fromMap(doc.data()!);
      }
    } catch (e) {
      error = "Error refreshing profile";
      debugPrint('Error refreshing profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCoverImages(String url, String uid) async {
    try {
      error = "";
      notifyListeners();
      // Update cover image in Firestore
      await _firestore.collection('students').doc(uid).update({
        'coverImageUrl': url,
      });

      _student = _student!.copyWith(coverImageUrl: url);
    } catch (e) {
      error = "Error updating cover image";
      debugPrint('Error refreshing profile: $e');
    }
    notifyListeners();
  }

  Future<void> updateProfileImage(String url, String uid) async {
    try {
      error = "";
      notifyListeners();
      // Update cover image in Firestore
      await _firestore.collection('students').doc(uid).update({
        'profileImageUrl': url,
      });

      _student = _student!.copyWith(profileImageUrl: url);
    } catch (e) {
      error = "Error updating porfile image";
      debugPrint('Error refreshing profile: $e');
    }

    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchCoachingDataBatched(
      List<String> coachingCodes) async {
    if (coachingCodes.isEmpty) return [];

    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> organizationData = [];

    for (var i = 0; i < coachingCodes.length; i += 10) {
      final batch = coachingCodes.sublist(
        i,
        i + 10 > coachingCodes.length ? coachingCodes.length : i + 10,
      );

      // Try cache first
      var cacheSnapshot = await firestore
          .collection('coachingCodes')
          .where(FieldPath.documentId, whereIn: batch)
          .get(const GetOptions(source: Source.cache));

      // If some documents are missing in cache, fetch from server
      if (cacheSnapshot.docs.length < batch.length) {
        var serverSnapshot = await firestore
            .collection('coachingCodes')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.server));

        // Merge results, avoiding duplicates
        final existingIds = cacheSnapshot.docs.map((doc) => doc.id).toSet();
        final mergedDocs = [
          ...cacheSnapshot.docs,
          ...serverSnapshot.docs.where((doc) => !existingIds.contains(doc.id))
        ];

        organizationData.addAll(mergedDocs.map((doc) {
          final data = doc.data();
          return {
            'name': data['name'],
            'logoUrl': data['logoUrl'],
            'code': data['code'],
          };
        }));
      } else {
        // All found in cache
        organizationData.addAll(cacheSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['name'],
            'logoUrl': data['logoUrl'],
            'code': data['code'],
          };
        }));
      }
    }
    return organizationData;
  }

  // Update student data in provider
  Future<void> updateStudentProfile(StudentModel student, String uid) async {
    try {
      error = "";
      notifyListeners();
      await _firestore
          .collection('students')
          .doc(uid) // Use student's UID
          .set(student.toMap(),
              SetOptions(merge: true)); // Merge instead of overwrite
      // Update locally first (instant UI change)
      _student = student.copyWith(
        email: _student!.email,
        profileImageUrl: _student!.profileImageUrl,
        coverImageUrl: _student!.coverImageUrl,
      );

      notifyListeners();
    } catch (e) {
      error = "Error updating student profile";
      notifyListeners();
      debugPrint("Error updating student profile: $e");
    }
  }
}
