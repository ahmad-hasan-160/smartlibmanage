import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/borrow.dart';
import 'book_list_screen.dart';

class UserDashboard extends StatelessWidget {
  final AppUser user;

  const UserDashboard({super.key, required this.user});

  int _calculateDaysRemaining(DateTime dueDate) {
    return dueDate.difference(DateTime.now()).inDays;
  }

  Color _getStatusColor(int daysRemaining, bool isReturned) {
    if (isReturned) return Colors.grey;
    if (daysRemaining < 0) return Colors.red;
    if (daysRemaining <= 3) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(int daysRemaining, bool isReturned) {
    if (isReturned) return 'Returned';
    if (daysRemaining < 0) return 'Overdue by ${-daysRemaining} day(s)';
    if (daysRemaining == 0) return 'Due today';
    if (daysRemaining == 1) return 'Due tomorrow';
    return 'Due in $daysRemaining days';
  }

  void _requestReturn(BuildContext context, String borrowId) async {
    final currentUser = await FirestoreService().getUser(user.uid);
    if (currentUser?.status == 'inactive') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot return book: Your account is inactive.')),
      );
      return;
    }
    
    await FirestoreService().requestReturn(borrowId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return request submitted! Waiting for admin confirmation.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Material(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookListScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('Search Books', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Borrowed'),
                Tab(text: 'Returned'),
              ],
            ),
            Expanded(
              child: StreamBuilder<List<BorrowRecord>>(
                stream: FirestoreService().getBorrowRecords(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final borrows = List<BorrowRecord>.from(snapshot.data!);
                  borrows.sort((a, b) => b.borrowDate.compareTo(a.borrowDate));

                  if (borrows.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No borrowed books', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final pending = borrows.where((b) => b.status == 'pending_borrow').toList();
                  final borrowed = borrows.where((b) => b.status == 'active' || b.status == 'pending_return').toList();
                  final returned = borrows.where((b) => b.status == 'returned' || b.isReturned).toList();

                  return TabBarView(
                    children: [
                      _buildBorrowList(context, user, pending),
                      _buildBorrowList(context, user, borrowed),
                      _buildBorrowList(context, user, returned),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowList(BuildContext context, AppUser user, List<BorrowRecord> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items here'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: items.map((b) => _buildBorrowCard(context, user, b)).toList(),
    );
  }

  Widget _buildBorrowCard(BuildContext context, AppUser user, BorrowRecord borrow) {
    return FutureBuilder<Book?>(
      future: FirestoreService().getBookById(borrow.bookId),
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

        final daysRemaining = _calculateDaysRemaining(borrow.dueDate);
        final statusColor = _getStatusColor(daysRemaining, borrow.isReturned);
        final statusText = _getStatusText(daysRemaining, borrow.isReturned);

        String statusBadge = '';
        Color badgeColor = Colors.grey;
        if (borrow.status == 'pending_borrow') {
          statusBadge = 'PENDING APPROVAL';
          badgeColor = Colors.orange;
        } else if (borrow.status == 'pending_return') {
          statusBadge = 'RETURN PENDING';
          badgeColor = Colors.blue;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: statusColor, width: 4),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12.0),
              leading: book.imageUrl != null && book.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        book.imageUrl!,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, size: 30),
                        ),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.book, size: 30),
                    ),
              title: Text(
                book.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('by ${book.author}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  if (statusBadge.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Borrowed: ${borrow.borrowDate.day}/${borrow.borrowDate.month}/${borrow.borrowDate.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: borrow.status == 'active'
                  ? FutureBuilder<AppUser?>(
                      future: FirestoreService().getUser(user.uid),
                      builder: (context, userSnapshot) {
                        final isInactive = userSnapshot.data?.status == 'inactive';
                        return IconButton(
                          icon: const Icon(Icons.assignment_return, color: Colors.blue),
                          tooltip: isInactive ? 'Cannot return: Account inactive' : 'Request Return',
                          onPressed: isInactive ? null : () => _requestReturn(context, borrow.id),
                        );
                      },
                    )
                  : borrow.isReturned
                      ? const Icon(Icons.check_circle, color: Colors.grey, size: 32)
                      : Icon(
                          borrow.status == 'pending_borrow' ? Icons.hourglass_empty : Icons.pending,
                          color: badgeColor,
                          size: 32,
                        ),
            ),
          ),
        );
      },
    );
  }
}