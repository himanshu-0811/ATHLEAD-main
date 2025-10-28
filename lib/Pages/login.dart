//login.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Required for catching exceptions
import 'signup.dart';
import 'home.dart';
import 'firebase_service.dart'; // New Import

class Sign extends StatelessWidget {
  const Sign({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Login(),
    );
  }
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, -0.7),
            end: Alignment(0.50, 1.00),
            colors: [
              Color(0xFF525832),
              Color(0xFF282A18),
              Color(0xFF1D1D1D),
            ],
          ),
        ),
        child: const SafeArea(
          child: _RegisterPanel(),
        ),
      ),
    );
  }
}

class _RegisterPanel extends StatefulWidget {
  const _RegisterPanel();

  @override
  State<_RegisterPanel> createState() => _RegisterPanelState();
}

class _RegisterPanelState extends State<_RegisterPanel> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  // Helper function to convert Firebase error codes to messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid username/email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userId = await firebaseService.login(
        _email.text,
        _password.text,
      );

      if (userId.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AndroidCompact2(userId: userId),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getFirebaseErrorMessage(e.code))),
      );
    } catch (e) {
      if (!mounted) return;
      // Handle generic errors (e.g., network issues)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: screenWidth < 500 ? screenWidth * 0.9 : 400, // responsive width
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7), // Fixed withValues
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Login',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildText('Email', _email),
                _buildText(
                  'Password',
                  _password,
                  obscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF525832),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New user? ", style: TextStyle(color: Colors.white70)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupPage()),
                        );
                      },
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Color(0xFFB1C900),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String label, TextEditingController ctrl,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB1C900)),
          ),
        ),
        validator:
        validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }
}