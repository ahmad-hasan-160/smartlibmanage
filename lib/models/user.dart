class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role;
  final List<String> borrowedBooks;
  final String status;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.borrowedBooks,
    this.status = 'active',
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      borrowedBooks: List<String>.from(data['borrowedBooks'] ?? []),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'borrowedBooks': borrowedBooks,
      'status': status,
    };
  }
}