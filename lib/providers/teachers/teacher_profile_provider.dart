import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/teachers/profile_modal.dart';
import '../../utils/cloudinary.dart';

class TeacherProfileProvider with ChangeNotifier {
  TeacherModel? _teacher;
  bool _isLoading = false;
  String _error = '';

  TeacherModel? get teacher => _teacher;
  bool get isLoading => _isLoading;
  String get error => _error;

  final _firestore = FirebaseFirestore.instance;

  Future<void> fetchTeacherProfile(String uid) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('teachers')
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      if (doc.exists) {
        _teacher = TeacherModel.fromMap(doc.data()!);
      } else {
        // If not in cache, fetch from server
        final serverDoc = await _firestore
            .collection('teachers')
            .doc(uid)
            .get(const GetOptions(source: Source.server));
        if (serverDoc.exists) {
          _teacher = TeacherModel.fromMap(serverDoc.data()!);
        }
      }
    } catch (e) {
      print(e);
      _error = 'Failed to fetch teacher profile!';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTeacherProfile(
      TeacherModel updatedTeacher, String uid) async {
    if (_teacher == null) return;

    _error = '';
    notifyListeners();
    try {
      // Preserve email and image URLs

      await _firestore
          .collection('teachers')
          .doc(uid)
          .update(updatedTeacher.toMap());

      _teacher = updatedTeacher.copyWith(
        teacherImageUrl: _teacher!.teacherImageUrl,
        email: _teacher!.email,
      );
    } catch (e) {
      _error = 'Failed to update profile: $e';
    }

    notifyListeners();
  }

  Future<void> updateImage(File file, String uid) async {
    if (_teacher == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final url = await uploadImageToCloudinary(
        file,
        folderName: "testify_learn/images",
      );
      await _firestore.collection('teachers').doc(uid).update({
        "teacherImageUrl": url,
      });

      _teacher = _teacher!.copyWith(teacherImageUrl: url);
    } catch (e) {
      _error = 'Image update failed: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfileData(String uid) async {
    await fetchTeacherProfile(uid);
  }
}
