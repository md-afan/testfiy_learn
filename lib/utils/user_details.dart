import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>?> userDetails(String uid, String collection) async {
  final doc =
      await FirebaseFirestore.instance.collection(collection).doc(uid).get();
  if (doc.exists) {
    return doc.data();
  }
  return null;
}
