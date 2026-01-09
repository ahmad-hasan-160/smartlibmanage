import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../services/firestore_service.dart';
import '../models/borrow.dart';
import '../models/feedback.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  double _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating && rating - index >= 0.5) {
          // Half star
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          // Empty star
          return Icon(Icons.star_border, color: Colors.amber, size: size);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${book.author}', style: const TextStyle(fontSize: 18)),
            Text('Category: ${book.category}', style: const TextStyle(fontSize: 18)),
            Text('ISBN: ${book.isbn}', style: const TextStyle(fontSize: 18)),
            Text('Available: ${book.availableCopies}/${book.totalCopies}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text(book.description),
            const SizedBox(height: 24),
            if (book.availableCopies > 0)
              _buildBorrowButton(context, user),
            const Divider(height: 32),
            const Text('Ratings & Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildFeedbackList(book.id),
            const SizedBox(height: 12),
            if (user != null) _buildFeedbackForm(book.id, user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowButton(BuildContext context, firebase_auth.User? user) {
    if (user == null) {
      return ElevatedButton(
        onPressed: null,
        child: const Text('Borrow Book'),
      );
    }

    return FutureBuilder<AppUser?>(
      future: FirestoreService().getUser(user.uid),
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        final isInactive = appUser?.status == 'inactive';

        return ElevatedButton(
          onPressed: isInactive ? null : () => _borrowBook(context, user.uid),
          child: Text(isInactive ? 'Account Inactive - Cannot Borrow' : 'Borrow Book'),
        );
      },
    );
  }

  Widget _buildFeedbackList(String bookId) {
    final currentUser = Provider.of<AuthProvider>(context).user;

    return StreamBuilder<List<FeedbackEntry>>(
      stream: FirestoreService().getFeedback(bookId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final feedback = snapshot.data!;
        if (feedback.isEmpty) {
          return const Text('No feedback yet. Be the first to rate and comment.');
        }

        final average = feedback.map((f) => f.rating).fold<double>(0, (a, b) => a + b) / feedback.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Average rating: ', style: TextStyle(fontWeight: FontWeight.w500)),
                _buildStarRating(average, size: 20),
                const SizedBox(width: 8),
                Text('${average.toStringAsFixed(1)} (${feedback.length} reviews)', 
                  style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            ...feedback.map(
              (f) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildStarRating(f.rating, size: 18),
                              const SizedBox(width: 6),
                              Text('${f.rating.toStringAsFixed(1)}', 
                                style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          if (currentUser != null && (f.userId == currentUser.uid || _isAdmin(context)))
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                              onPressed: () => _deleteReview(context, bookId, f.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            f.userName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            f.userEmail,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (f.comment.isNotEmpty)
                        Text(f.comment),
                      Text(
                        '${f.createdAt.year}-${f.createdAt.month.toString().padLeft(2, '0')}-${f.createdAt.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackForm(String bookId, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Text('Rating: '),
            const SizedBox(width: 8),
            _buildStarRating(_rating, size: 24),
            const SizedBox(width: 8),
            Text(_rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _rating,
          min: 1,
          max: 5,
          divisions: 8,
          label: _rating.toStringAsFixed(1),
          onChanged: (val) => setState(() => _rating = val),
        ),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(labelText: 'Comment (optional)'),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => _submitFeedback(bookId, userId),
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback(String bookId, String userId) async {
    // Fetch user information
    final user = await FirestoreService().getUser(userId);
    
    final entry = FeedbackEntry(
      id: '',
      userId: userId,
      userName: user?.name ?? 'Anonymous',
      userEmail: user?.email ?? '',
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );
    await FirestoreService().addFeedback(entry, bookId);
    if (mounted) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your feedback')));
    }
  }

  void _borrowBook(BuildContext context, String userId) async {
    final borrowDate = DateTime.now();
    final dueDate = borrowDate.add(const Duration(days: 14));
    final record = BorrowRecord(
      id: '',
      userId: userId,
      bookId: widget.book.id,
      borrowDate: borrowDate,
      dueDate: dueDate,
      isReturned: false,
      status: 'pending_borrow',
    );
    await FirestoreService().borrowBook(record);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borrow request submitted! Waiting for admin approval.')));
    if (mounted) Navigator.pop(context);
  }

  bool _isAdmin(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return false;
    return user.email == 'admin@gmail.com';
  }

  void _deleteReview(BuildContext context, String bookId, String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: const Text('Are you sure you want to delete this review?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirestoreService().deleteFeedback(bookId, reviewId);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review deleted')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}