import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';

class BookProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];

  List<Book> get books => _filteredBooks;

  BookProvider() {
    loadBooks();
  }

  void loadBooks() {
    _firestoreService.getBooks().listen((books) {
      _books = books;
      _filteredBooks = books;
      notifyListeners();
    });
  }

  void searchBooks(String query) {
    if (query.isEmpty) {
      _filteredBooks = _books;
    } else {
      _filteredBooks = _books.where((book) =>
          book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase()) ||
          book.category.toLowerCase().contains(query.toLowerCase())).toList();
    }
    notifyListeners();
  }

  Future<void> addBook(Book book) async {
    await _firestoreService.addBook(book);
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await _firestoreService.updateBook(id, data);
  }

  Future<void> deleteBook(String id) async {
    await _firestoreService.deleteBook(id);
  }
}