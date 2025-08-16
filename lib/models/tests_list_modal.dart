// class Quiz {
//   final String id;
//   final String title;
//   final DateTime? testDateTime;
//   final DateTime createdAt;
//   final String status;
//   final bool isPublished;
//   final bool isEnrolled;
//   final String coachingCode;

//   Quiz({
//     required this.id,
//     required this.title,
//     required this.testDateTime,
//     required this.createdAt,
//     required this.status,
//     required this.isPublished,
//     required this.isEnrolled,
//     required this.coachingCode,
//   });

//   factory Quiz.fromFirestore(DocumentSnapshot doc, bool isEnrolled) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Quiz(
//       id: doc.id,
//       title: data['title'] ?? 'Untitled',
//       testDateTime: (data['testDateTime'] as Timestamp?)?.toDate(),
//       createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
//       status: (data['status'] ?? '').toString(),
//       isPublished: data['isPublished'] ?? false,
//       isEnrolled: isEnrolled,
//       coachingCode: data['coachingCode'] ?? '',
//     );
//   }

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is Quiz &&
//           runtimeType == other.runtimeType &&
//           id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }