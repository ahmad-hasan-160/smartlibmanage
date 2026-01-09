import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/firestore_service.dart';
import '../models/user.dart';
import 'user_dashboard.dart';
import 'admin_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<AppUser?>(
      future: FirestoreService().getUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          final appUser = snapshot.data!;
          if (appUser.role == 'admin' || appUser.role == 'librarian') {
            return AdminDashboard(user: appUser);
          } else {
            return UserDashboard(user: appUser);
          }
        }
        return FutureBuilder<AppUser>(
          future: _createUserIfNotExists(user),
          builder: (context, createSnapshot) {
            if (createSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (createSnapshot.hasData) {
              final appUser = createSnapshot.data!;
              if (appUser.role == 'admin' || appUser.role == 'librarian') {
                return AdminDashboard(user: appUser);
              } else {
                return UserDashboard(user: appUser);
              }
            }
            return const Center(child: Text('Error creating user data'));
          },
        );
      },
    );
  }

  Future<AppUser> _createUserIfNotExists(User firebaseUser) async {
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      role: 'student',
      borrowedBooks: [],
    );
    await FirestoreService().addUser(appUser);
    return appUser;
  }
}