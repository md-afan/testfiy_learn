import "package:cloud_firestore/cloud_firestore.dart";

class CacheManager {
  static Future<void> preloadEssentialData() async {
    await Future.wait([
      _preloadCollection('quizzes', limit: 20),
      _preloadCollection('categories'),
      _preloadCollection('leaderboard', limit: 10),
    ]);
  }

  static Future<void> _preloadCollection(String path, {int? limit}) async {
    Query query = FirebaseFirestore.instance.collection(path);
    if (limit != null) query = query.limit(limit);

    await query.get(GetOptions(source: Source.server));
  }

  static Future<void> clearStaleCache() async {
    final firestore = FirebaseFirestore.instance;

    // Clear cache older than 7 days
    await firestore.clearPersistence();

    // Alternatively, clear specific collections
    await _clearCollectionCache('quizzes');
    await _clearCollectionCache('users');
  }

  static Future<void> _clearCollectionCache(String path) async {
    final query = FirebaseFirestore.instance.collection(path);
    final snapshot = await query.get(GetOptions(source: Source.cache));

    for (final doc in snapshot.docs) {
      doc.reference.get(GetOptions(source: Source.cache));
    }
  }
}
