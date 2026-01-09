import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackEntry {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final double rating;
  final String comment;
  final DateTime createdAt;

  FeedbackEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory FeedbackEntry.fromMap(String id, Map<String, dynamic> data) {
    return FeedbackEntry(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userEmail: data['userEmail'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
        createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
