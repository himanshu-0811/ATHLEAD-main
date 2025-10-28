// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart';


void main() async {
  // 1. Ensure Flutter bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase Core
  // This is essential for all Auth/Firestore calls in the app.
  await Firebase.initializeApp();

  runApp(const Athlead());
}

class Athlead extends StatelessWidget {
  const Athlead({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      // Set the home to the initial login/signup page ('Sign' in login.dart)
      home: const Sign(),
    );
  }
}