import 'package:cloud_firestore/cloud_firestore.dart';
import "../utils/secure_locally_storage.dart";

Future<String?> getUserRole(String uid) async {
  final firestore = FirebaseFirestore.instance;
  try {
    // Check in teachers collection
    final teacherDoc =
        await firestore.collection('teachers').doc(uid).get(const GetOptions());
    if (teacherDoc.exists) {
      if (teacherDoc.data()?['isAdmin'] == true) {
        await LocalStorage.saveLocalStorage("coachingCode",
            teacherDoc.data()?['coachingCode']?.toString() ?? '');
        return 'teacher_admin';
      } else {
        return 'teacher';
      }
    }

    final studentDoc = await firestore.collection('students').doc(uid).get();
    if (studentDoc.exists) {
      return 'student';
    }

    // If not found in both
    return null;
  } catch (e) {
    print('Error fetching user role: $e');
    return null;
  }
}

Future<bool> isGoogleWithSignIn(String uid) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection("students").doc(uid).get();

    if (doc.exists) {
      final data = doc.data();
      return data?['isGoogle'] == true;
    } else {
      return false;
    }
  } catch (e) {
    print("Error checking Google Sign-In status: $e");
    return false;
  }
}

Future<String?> coachingCode(String uid) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection("teachers").doc(uid).get();

    if (doc.exists && doc.data() != null) {
      return doc.data()!['coachingCode'] as String?;
    } else {
      return null;
    }
  } catch (e) {
    print("Error fetching coachingCode for uid '$uid': $e");
    return null;
  }
}

Future<Map<String, dynamic>?> userDetails(
  String uid,
  String collections,
) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection(collections).doc(uid).get();

    if (doc.exists && doc.data() != null) {
      return doc.data();
    } else {
      return null;
    }
  } catch (e) {
    print("Error fetching userDetails for uid '$uid': $e");
    return null;
  }
}
