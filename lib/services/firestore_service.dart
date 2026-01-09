import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/book.dart';
import '../models/user.dart';
import '../models/borrow.dart';
import '../models/feedback.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Book>> getBooks() {
    return _db.collection('books').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Book.fromMap(doc.id, doc.data())).toList());
  }

  Future<Book?> getBookById(String bookId) async {
    DocumentSnapshot doc = await _db.collection('books').doc(bookId).get();
    if (doc.exists) {
      return Book.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> addBook(Book book) async {
    await _db.collection('books').add(book.toMap());
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await _db.collection('books').doc(id).update(data);
  }

  Future<void> deleteBook(String id) async {
    await _db.collection('books').doc(id).delete();
  }

  Future<void> addUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUserStatus(String uid, String status) async {
    await _db.collection('users').doc(uid).update({'status': status});
  }

  Future<AppUser?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<AppUser>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Stream<List<BorrowRecord>> getBorrowRecords(String userId) {
    return _db.collection('borrows').where('userId', isEqualTo: userId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => BorrowRecord.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<BorrowRecord>> getAllBorrowRecordsByUser(String userId) {
    return _db.collection('borrows')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BorrowRecord.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> borrowBook(BorrowRecord record) async {
    await _db.collection('borrows').add(record.toMap());
  }

  Future<void> returnBook(String borrowId, DateTime returnDate) async {
    await _db.collection('borrows').doc(borrowId).update({
      'returnDate': Timestamp.fromDate(returnDate),
      'isReturned': true,
    });
  }

  Future<void> requestReturn(String borrowId) async {
    await _db.collection('borrows').doc(borrowId).update({
      'status': 'pending_return',
    });
  }

  Stream<List<BorrowRecord>> getPendingRequests() {
    return _db.collection('borrows')
        .where('status', whereIn: ['pending_borrow', 'pending_return'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BorrowRecord.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> approveBorrowRequest(String borrowId) async {
    await _db.runTransaction((transaction) async {
      final borrowRef = _db.collection('borrows').doc(borrowId);
      final borrowSnap = await transaction.get(borrowRef);
      if (!borrowSnap.exists) {
        throw Exception('Borrow record not found');
      }

      final borrowData = borrowSnap.data() as Map<String, dynamic>;
      if (borrowData['status'] != 'pending_borrow') {
        throw Exception('Request is not pending approval');
      }

      final bookId = borrowData['bookId'] as String? ?? '';
      if (bookId.isEmpty) {
        throw Exception('Book ID missing on request');
      }

      final bookRef = _db.collection('books').doc(bookId);
      final bookSnap = await transaction.get(bookRef);
      if (!bookSnap.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookSnap.data() as Map<String, dynamic>;
      final available = (bookData['availableCopies'] ?? 0) as int;
      if (available <= 0) {
        throw Exception('No copies available');
      }

      transaction.update(bookRef, {'availableCopies': available - 1});
      transaction.update(borrowRef, {
        'status': 'active',
      });
    });
  }

  Future<void> approveReturnRequest(String borrowId) async {
    await _db.runTransaction((transaction) async {
      final borrowRef = _db.collection('borrows').doc(borrowId);
      final borrowSnap = await transaction.get(borrowRef);
      if (!borrowSnap.exists) {
        throw Exception('Borrow record not found');
      }

      final borrowData = borrowSnap.data() as Map<String, dynamic>;
      if (borrowData['status'] != 'pending_return') {
        throw Exception('Request is not pending return');
      }

      final bookId = borrowData['bookId'] as String? ?? '';
      if (bookId.isEmpty) {
        throw Exception('Book ID missing on request');
      }

      final bookRef = _db.collection('books').doc(bookId);
      final bookSnap = await transaction.get(bookRef);
      if (!bookSnap.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookSnap.data() as Map<String, dynamic>;
      final available = (bookData['availableCopies'] ?? 0) as int;

      transaction.update(bookRef, {'availableCopies': available + 1});
      transaction.update(borrowRef, {
        'status': 'returned',
        'isReturned': true,
        'returnDate': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> rejectRequest(String borrowId, String currentStatus) async {
    if (currentStatus == 'pending_borrow') {
      await _db.collection('borrows').doc(borrowId).delete();
    } else if (currentStatus == 'pending_return') {
      await _db.collection('borrows').doc(borrowId).update({
        'status': 'active',
      });
    }
  }

  Stream<List<FeedbackEntry>> getFeedback(String bookId) {
    return _db
        .collection('books')
        .doc(bookId)
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackEntry.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addFeedback(FeedbackEntry entry, String bookId) async {
    await _db
        .collection('books')
        .doc(bookId)
        .collection('feedback')
        .add(entry.toMap());
  }

  Future<void> deleteFeedback(String bookId, String feedbackId) async {
    await _db
        .collection('books')
        .doc(bookId)
        .collection('feedback')
        .doc(feedbackId)
        .delete();
  }

  Future<String> uploadBookImage(File imageFile) async {
    try {
      print('Starting image upload...');
      
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }
      
      final fileSize = await imageFile.length();
      print('File size: $fileSize bytes');
      
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }
      
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image file is too large (max 10MB)');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'book_$timestamp.jpg';
      print('Uploading as: books/$fileName');
      
      final Reference storageRef = _storage.ref().child('books').child(fileName);
      
      UploadTask uploadTask = storageRef.putFile(imageFile);
      
      await uploadTask.whenComplete(() => print('Upload complete'));
      
      print('Getting download URL...');
      final String downloadUrl = await storageRef.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Upload error details: $e');
      rethrow;
    }
  }
}