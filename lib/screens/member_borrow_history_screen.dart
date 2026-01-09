import 'package:flutter/material.dart';
import '../models/borrow.dart';
import '../models/book.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class MemberBorrowHistoryScreen extends StatelessWidget {
  final AppUser member;

  const MemberBorrowHistoryScreen({super.key, required this.member});

  int _calculateDaysRemaining(DateTime dueDate) {
    return dueDate.difference(DateTime.now()).inDays;
  }

  Color _getStatusColor(String status, int daysRemaining, bool isReturned) {
    if (status == 'pending_borrow') return Colors.orange;
    if (status == 'pending_return') return Colors.blue;
    if (isReturned || status == 'returned') return Colors.grey;
    if (daysRemaining < 0) return Colors.red;
    if (daysRemaining <= 3) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(String status, int daysRemaining, bool isReturned) {
    if (status == 'pending_borrow') return 'Pending Approval';
    if (status == 'pending_return') return 'Return Pending';
    if (isReturned || status == 'returned') return 'Returned';
    if (daysRemaining < 0) return 'Overdue by ${-daysRemaining} day(s)';
    if (daysRemaining == 0) return 'Due Today';
    if (daysRemaining == 1) return 'Due Tomorrow';
    return 'Due in $daysRemaining days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${member.name}\'s History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              member.role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Complete Borrowing History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BorrowRecord>>(
              stream: FirestoreService().getAllBorrowRecordsByUser(member.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = snapshot.data!;
                if (records.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No borrowing history',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                records.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return FutureBuilder<Book?>(
                      future: FirestoreService().getBookById(record.bookId),
                      builder: (context, bookSnapshot) {
                        if (!bookSnapshot.hasData) {
                          return const Card(
                            child: ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('Loading...'),
                            ),
                          );
                        }

                        final book = bookSnapshot.data;
                        if (book == null) {
                          return const SizedBox.shrink();
                        }

                        final daysRemaining = _calculateDaysRemaining(record.dueDate);
                        final statusColor = _getStatusColor(record.status, daysRemaining, record.isReturned);
                        final statusText = _getStatusText(record.status, daysRemaining, record.isReturned);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          elevation: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: statusColor, width: 5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Borrowed: ${record.borrowDate.day}/${record.borrowDate.month}/${record.borrowDate.year}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.event, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Due: ${record.dueDate.day}/${record.dueDate.month}/${record.dueDate.year}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                        if (record.returnDate != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle, size: 14, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Returned: ${record.returnDate!.day}/${record.returnDate!.month}/${record.returnDate!.year}',
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
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
