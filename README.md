# SmartLibManage

A Flutter-based Smart Library Management System for Android.

## Features

- User authentication with Firebase (role-based: Admin/Student/Teacher)
- Book catalog with search functionality
- Book inventory management (Add/Edit/Delete)
- Borrowing and returning workflow with admin approval
- Real-time notifications for due dates
- Separate dashboards for Admin and Members

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install

2. Clone the repository:
   ```
   git clone https://github.com/ahmad-hasan-160/smartlibmanage.git
   ```

3. Set up Firebase:
   - Create a Firebase project at https://console.firebase.google.com/
   - Enable Authentication, Firestore, and Cloud Messaging.
   - Download google-services.json and place it in android/app/
   - For iOS, download GoogleService-Info.plist and place in ios/Runner/

4. Install dependencies:
   ```
   flutter pub get
   ```

5. Run the app:
   ```
   flutter run
   ```

## Firebase Configuration

- Authentication: Email/Password
- Firestore collections:
  - users: {uid, email, name, role, borrowedBooks[]}
  - books: {title, author, category, isbn, totalCopies, availableCopies, description, imageUrl}
  - borrows: {userId, bookId, borrowDate, dueDate, returnDate, isReturned}

## Usage

- **Admin:** Add/edit/delete books, approve borrow/return requests, manage users
- **Students/Teachers:** Browse catalog, search books, request borrow/return

## Technologies

- Flutter & Dart
- Firebase (Auth, Firestore, Cloud Messaging)
- Provider for state management

## Repository

https://github.com/ahmad-hasan-160/smartlibmanage
