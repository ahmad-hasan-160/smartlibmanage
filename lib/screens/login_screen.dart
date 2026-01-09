import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'student';
  bool _isLogin = true;
  bool _adminMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartLibManage'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.library_books, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Library Management System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Student / Teacher'),
                    selected: !_adminMode,
                    onSelected: (_) {
                      setState(() {
                        _adminMode = false;
                        _isLogin = true;
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Admin'),
                    selected: _adminMode,
                    selectedColor: adminColor.withOpacity(0.2),
                    onSelected: (_) {
                      setState(() {
                        _adminMode = true;
                        _isLogin = true;
                        _role = 'student';
                        _emailController.text = 'admin@gmail.com';
                        _passwordController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
            if (!_adminMode && !_isLogin) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                ],
                onChanged: (value) {
                  setState(() {
                    _role = value ?? 'student';
                  });
                },
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _authenticate,
                child: Text(
                  _adminMode
                      ? 'Admin Login'
                      : _isLogin
                          ? 'Login'
                          : 'Sign Up',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_adminMode)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Login',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (_adminMode)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Text(
                  'Admin login uses email admin@gmail.com\nand the current admin password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _authenticate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (_adminMode) {
        await authProvider.signIn(_emailController.text, _passwordController.text);
      } else if (_isLogin) {
        await authProvider.signIn(_emailController.text, _passwordController.text);
      } else {
        await authProvider.signUp(_emailController.text, _passwordController.text, _nameController.text, _role);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}