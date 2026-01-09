import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRecord {
  final String id;
  final String userId;
  final String bookId;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final bool isReturned;
  final String status;

  BorrowRecord({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.isReturned,
    this.status = 'active',
  });

  factory BorrowRecord.fromMap(String id, Map<String, dynamic> data) {
    return BorrowRecord(
      id: id,
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      borrowDate: (data['borrowDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      returnDate: data['returnDate'] != null ? (data['returnDate'] as Timestamp).toDate() : null,
      isReturned: data['isReturned'] ?? false,
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'borrowDate': Timestamp.fromDate(borrowDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'isReturned': isReturned,
      'status': status,
    };
  }
}