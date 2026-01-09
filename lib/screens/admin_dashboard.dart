import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../services/firestore_service.dart';
import 'add_book_screen.dart';
import 'manage_books_screen.dart';
import 'pending_requests_screen.dart';
import 'member_borrow_history_screen.dart';

class AdminDashboard extends StatelessWidget {
  final AppUser user;

  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard - ${user.name}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.withOpacity(0.1),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.orange),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.pending_actions, color: Colors.purple),
                  title: const Text('Pending Requests'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingRequestsScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.library_books, color: Colors.blue),
                  title: const Text('Manage Books'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBooksScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.green),
                  title: const Text('Manage Members'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _showMembersDialog(context),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Admin Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = controller.text.trim();
                if (newPassword.isEmpty) return;
                try {
                  await Provider.of<AuthProvider>(context, listen: false).updatePassword(newPassword);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showMembersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Manage Members'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StreamBuilder<List<AppUser>>(
              stream: FirestoreService().getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.where((u) => u.role != 'admin').toList();
                if (users.isEmpty) {
                  return const Center(child: Text('No members found'));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final member = users[index];
                    final roleColor = member.role == 'teacher' ? Colors.blue : Colors.green;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: roleColor.withOpacity(0.2),
                              foregroundColor: roleColor,
                              child: Text(
                                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    member.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    member.role.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: roleColor, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    member.status == 'inactive' ? 'Status: INACTIVE' : 'Status: ACTIVE',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: member.status == 'inactive' ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.history, color: Colors.blue),
                                  tooltip: 'View History',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MemberBorrowHistoryScreen(member: member),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    member.status == 'inactive' ? Icons.check_circle : Icons.pause_circle_filled,
                                    color: member.status == 'inactive' ? Colors.green : Colors.orange,
                                    size: 26,
                                  ),
                                  tooltip: member.status == 'inactive' ? 'Activate' : 'Deactivate',
                                  onPressed: () => _toggleMemberStatus(context, member),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete Member',
                                  onPressed: () => _confirmDeleteMember(context, member),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteMember(BuildContext context, AppUser member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Member'),
          content: Text('Are you sure you want to delete ${member.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirestoreService().deleteUser(member.uid);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${member.name} deleted')),
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

  void _toggleMemberStatus(BuildContext context, AppUser member) async {
    final targetStatus = member.status == 'inactive' ? 'active' : 'inactive';
    try {
      await FirestoreService().updateUserStatus(member.uid, targetStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} is now ${targetStatus.toUpperCase()}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}