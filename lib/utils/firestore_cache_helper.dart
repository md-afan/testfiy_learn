// Firestore helper class with caching strategies
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCacheHelper {
  static Future<DocumentSnapshot> getDocumentWithCache(
    String path, {
    Source source = Source.cache,
    Duration cacheDuration = const Duration(minutes: 15),
    bool forceRefresh = false,
  }) async {
    final docRef = FirebaseFirestore.instance.doc(path);
    final cacheData = await _getCachedDoc(docRef, cacheDuration);

    if (cacheData != null && !forceRefresh) {
      return cacheData;
    }

    return await docRef.get(GetOptions(source: source));
  }

  static Future<QuerySnapshot> getCollectionWithCache(
    String path, {
    Query Function(Query query)? queryBuilder,
    Source source = Source.cache,
    Duration cacheDuration = const Duration(minutes: 15),
    bool forceRefresh = false,
  }) async {
    Query query = FirebaseFirestore.instance.collection(path);
    if (queryBuilder != null) query = queryBuilder(query);

    final cacheData = await _getCachedQuery(query, cacheDuration);

    if (cacheData != null && !forceRefresh) {
      return cacheData;
    }

    return await query.get(GetOptions(source: source));
  }

  static Future<DocumentSnapshot?> _getCachedDoc(
    DocumentReference ref,
    Duration duration,
  ) async {
    try {
      final doc = await ref.get(GetOptions(source: Source.cache));
      final cacheTime = doc.metadata.isFromCache
          ? DateTime.now()
          : DateTime.now().subtract(duration);

      if (DateTime.now().difference(cacheTime) < duration) {
        return doc;
      }
    } catch (_) {}
    return null;
  }

  static Future<QuerySnapshot?> _getCachedQuery(
    Query query,
    Duration duration,
  ) async {
    try {
      final snapshot = await query.get(GetOptions(source: Source.cache));
      final cacheTime = snapshot.metadata.isFromCache
          ? DateTime.now()
          : DateTime.now().subtract(duration);

      if (DateTime.now().difference(cacheTime) < duration) {
        return snapshot;
      }
    } catch (_) {}
    return null;
  }
}
