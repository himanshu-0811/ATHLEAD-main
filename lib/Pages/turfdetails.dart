// full_seeder_script.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Default hourly slots used by most venues
const List<String> _defaultHourlySlots = [
  "07:00-08:00", "08:00-09:00", "09:00-10:00", "10:00-11:00",
  "11:00-12:00", "12:00-13:00", "13:00-14:00", "14:00-15:00",
  "15:00-16:00", "16:00-17:00", "17:00-18:00", "18:00-19:00",
  "19:00-20:00", "20:00-21:00",
];



// ---------------- SPECIFIC SPORTS CLUBS ----------------
final List<Map<String, dynamic>> _specificSportsClubs = [
  {
    'name': 'Andheri Chess Club',
    'sport': 'Chess',
    'address': 'Andheri West, Mumbai',
    'contact': '+91 9876543210',
    'capacity': 50,
    'zone': 'Western',
    'station': 'Andheri',
    'timeSlots': _defaultHourlySlots,
  },
  {
    'name': 'Dadar Table Tennis Center',
    'sport': 'Table Tennis',
    'address': 'Dadar East, Mumbai',
    'contact': '+91 9123456789',
    'capacity': 30,
    'zone': 'Central',
    'station': 'Dadar',
    'timeSlots': _defaultHourlySlots,
  },
];

// ---------------- SEEDING FUNCTION ----------------
Future<void> _seedFirestore() async {
  final firestore = FirebaseFirestore.instance;

  try {
    print('🏁 Starting Sports Club Upload (${_specificSportsClubs.length})...');
    for (var club in _specificSportsClubs) {
      await firestore.collection("sports_clubs").add(club);
    }
    print('✅ Sports clubs uploaded successfully!');

  } catch (e) {
    print('❌ Error during seeding: $e');
  }
}

// ---------------- APP ENTRY ----------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const SeederApp());
}

// ---------------- SIMPLE UI ----------------
class SeederApp extends StatefulWidget {
  const SeederApp({super.key});
  @override
  State<SeederApp> createState() => _SeederAppState();
}

class _SeederAppState extends State<SeederApp> {
  String message = "Starting Firestore Seeding...";

  @override
  void initState() {
    super.initState();
    _runSeeding();
  }

  Future<void> _runSeeding() async {
    try {
      await _seedFirestore();
      setState(() => message = "✅ Seeding Completed Successfully!\nCheck Firestore now.");
    } catch (e) {
      setState(() => message = "❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
himanshusharma33859@gmail.com
Him@123
