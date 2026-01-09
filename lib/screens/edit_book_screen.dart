import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/feedback.dart';
import '../providers/book_provider.dart';
import '../services/firestore_service.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _categoryController;
  late TextEditingController _isbnController;
  late TextEditingController _totalCopiesController;
  late TextEditingController _availableCopiesController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _categoryController = TextEditingController(text: widget.book.category);
    _isbnController = TextEditingController(text: widget.book.isbn);
    _totalCopiesController =
        TextEditingController(text: widget.book.totalCopies.toString());
    _availableCopiesController =
        TextEditingController(text: widget.book.availableCopies.toString());
    _descriptionController = TextEditingController(text: widget.book.description);
    _imageUrlController = TextEditingController(text: widget.book.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _isbnController.dispose();
    _totalCopiesController.dispose();
    _availableCopiesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField('Title', _titleController),
            _buildTextField('Author', _authorController),
            _buildTextField('Category', _categoryController),
            _buildTextField('ISBN', _isbnController),
            _buildTextField('Total Copies', _totalCopiesController, isNumber: true),
            _buildTextField('Available Copies', _availableCopiesController, isNumber: true),
            _buildTextField('Image URL (optional)', _imageUrlController),
            _buildTextField('Description', _descriptionController, maxLines: 4),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUpdating ? null : _updateBook,
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
            const Text('Member Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildReviewsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<FeedbackEntry>>(
      stream: FirestoreService().getFeedback(widget.book.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return const Text('No reviews yet');
        }

        return Column(
          children: reviews
              .map(
                (review) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${review.rating} / 5',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (review.comment.isNotEmpty)
                                Text(review.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text(
                                '${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}-${review.createdAt.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReview(review.id),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _updateBook() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final totalCopies = int.tryParse(_totalCopiesController.text) ?? widget.book.totalCopies;
      final availableCopies = int.tryParse(_availableCopiesController.text) ?? widget.book.availableCopies;
      final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();

      final updates = {
        'title': _titleController.text,
        'author': _authorController.text,
        'category': _categoryController.text,
        'isbn': _isbnController.text,
        'totalCopies': totalCopies,
        'availableCopies': availableCopies,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
      };
      await Provider.of<BookProvider>(context, listen: false)
          .updateBook(widget.book.id, updates);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Book updated')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _deleteReview(String reviewId) {
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
                await FirestoreService().deleteFeedback(widget.book.id, reviewId);
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

