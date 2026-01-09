import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrow.dart';
import '../models/book.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../providers/book_provider.dart';
import 'member_borrow_history_screen.dart';

class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
      ),
      body: StreamBuilder<List<BorrowRecord>>(
        stream: FirestoreService().getPendingRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending requests', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(context, request);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, BorrowRecord request) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        FirestoreService().getBookById(request.bookId),
        FirestoreService().getUser(request.userId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            ),
          );
        }

        final book = snapshot.data![0] as Book?;
        final user = snapshot.data![1] as AppUser?;

        if (book == null || user == null) {
          return const SizedBox.shrink();
        }

        final isBorrowRequest = request.status == 'pending_borrow';
        final cardColor = isBorrowRequest ? Colors.orange : Colors.blue;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          elevation: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: cardColor, width: 6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isBorrowRequest ? 'BORROW REQUEST' : 'RETURN REQUEST',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (book.imageUrl != null && book.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book.imageUrl!,
                            width: 60,
                            height: 85,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 85,
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 35),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.book, size: 35),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${book.author}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.history, size: 20, color: Colors.deepPurple),
                                  tooltip: 'View Full History',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MemberBorrowHistoryScreen(member: user),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user.email,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Request Date: ${request.borrowDate.day}/${request.borrowDate.month}/${request.borrowDate.year}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (!isBorrowRequest) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.event, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due Date: ${request.dueDate.day}/${request.dueDate.month}/${request.dueDate.year}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _rejectRequest(context, request),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _approveRequest(context, request, book, isBorrowRequest),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _approveRequest(BuildContext context, BorrowRecord request, Book book, bool isBorrowRequest) async {
    try {
      if (isBorrowRequest) {
        await FirestoreService().approveBorrowRequest(request.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Borrow request approved for ${book.title}')),
        );
      } else {
        await FirestoreService().approveReturnRequest(request.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Return confirmed for ${book.title}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _rejectRequest(BuildContext context, BorrowRecord request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: Text('Are you sure you want to reject this ${request.status == 'pending_borrow' ? 'borrow' : 'return'} request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await FirestoreService().rejectRequest(request.id, request.status);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    }
  }
}
