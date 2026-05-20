import 'package:flutter/material.dart';
// import '../../core/api_service.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // final _usernameCtrl = TextEditingController();
  // final _passwordCtrl = TextEditingController();
  final _nimNipCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'Mahasiswa';
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    // final res = await ApiService.post('api/register', {
    //   'username': _usernameCtrl.text,
    //   'password': _passwordCtrl.text,
    // });

    final res = await AuthService.register(
      _nimNipCtrl.text,
      _namaCtrl.text,
      _role,
      _passwordCtrl.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res.status == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Please login.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      // body: Padding(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            TextField(
              // controller: _usernameCtrl,
              // decoration: const InputDecoration(labelText: 'Username'),
              controller: _nimNipCtrl,
              decoration: const InputDecoration(labelText: 'NIM / NIP'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: ['Mahasiswa', 'Admin'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _role = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}
