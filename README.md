# SmartLibManage

A Flutter-based library management system for Android.

## Features

- User authentication with Firebase
- Book inventory management
- Borrowing and returning books
- QR code scanning for returns
- Real-time notifications
- Separate dashboards for students and librarians

## Setup

1. Install Flutter: https://flutter.dev/docs/get-started/install

2. Clone or download the project.

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

- Librarians can add/edit books, manage inventory.
- Students can search books, borrow, and return via QR scan.

## Technologies

- Flutter
- Firebase (Auth, Firestore, Messaging)
- Provider for state management
- QR Code Scanner
