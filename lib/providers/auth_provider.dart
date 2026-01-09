import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = 'admin123';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_isAdminEmail(normalizedEmail)) {
      await _signInAdmin(normalizedEmail, password);
      await _ensureAdminProfile();
      return;
    }

    await _auth.signInWithEmailAndPassword(email: normalizedEmail, password: password);
  }

  Future<void> signUp(String email, String password, String name, String role) async {
    if (_isAdminEmail(email)) {
      throw Exception('Admin account is login-only.');
    }

    if (role != 'student' && role != 'teacher') {
      throw Exception('Invalid role. Choose student or teacher.');
    }

    final normalizedEmail = email.trim().toLowerCase();

    await _auth.createUserWithEmailAndPassword(email: normalizedEmail, password: password);
    final user = _auth.currentUser;
    if (user != null) {
      final appUser = AppUser(
        uid: user.uid,
        email: normalizedEmail,
        name: name,
        role: role,
        borrowedBooks: [],
        status: 'active',
      );
      await FirestoreService().addUser(appUser);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }
    await currentUser.updatePassword(newPassword);
  }

  bool _isAdminEmail(String email) {
    return email == adminEmail;
  }

  Future<void> _ensureAdminProfile() async {
    final current = _auth.currentUser;
    if (current == null) return;

    final existing = await FirestoreService().getUser(current.uid);
    if (existing != null) return;

    final adminUser = AppUser(
      uid: current.uid,
      email: current.email ?? adminEmail,
      name: 'Admin',
      role: 'admin',
      borrowedBooks: [],
      status: 'active',
    );
    await FirestoreService().addUser(adminUser);
  }

  Future<void> _signInAdmin(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      if (password == adminPassword) {
        try {
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
          return;
        } on FirebaseAuthException catch (createError) {
          if (createError.code == 'email-already-in-use') {
            throw Exception('Admin account exists but password is incorrect.');
          }
          rethrow;
        }
      } else {
        throw Exception('Incorrect admin password.');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}