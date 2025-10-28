//signup.dart
import 'package:flutter/material.dart';
import 'login.dart';
import 'firebase_service.dart'; // New Import

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullname = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _fullname, _username, _password, _age, _phone, _email,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Replaced Firebase Auth and Firestore calls with mock service call
      final userId = await firebaseService.register({
        "fullname": _fullname.text.trim(),
        "username": _username.text.trim(),
        "age": _age.text.trim(),
        "phone": _phone.text.trim(),
        "email": _email.text.trim(),
        "password": _password.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful! Please login.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'The account already exists for that email.';
      } else {
        errorMessage = 'An error occurred during registration. Please try again. Error: $e';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: screenWidth * 0.9,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8), // Fixed withValues
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Sign Up",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextFormField("Full Name", controller: _fullname),
                    _buildTextFormField("Username", controller: _username),
                    _buildTextFormField("Password", controller: _password, isPassword: true),
                    _buildTextFormField("Age", controller: _age),
                    _buildTextFormField("Phone", controller: _phone),
                    _buildTextFormField("Email", controller: _email, validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    }),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Register", style: TextStyle(color: Colors.white)),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const Login()),
                            );
                          },
                          child: const Text("Login", style: TextStyle(color: Colors.yellow)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String hint, {TextEditingController? controller, bool isPassword = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $hint';
          }
          return null;
        },
      ),
    );
  }
}