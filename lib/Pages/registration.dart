//registration.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

// --- THEME COLORS ---
const Color kPrimaryColor = Color(0xFF525832);
const Color kAccentColor = Color(0xFFB1C900);
const Color kDarkBackground = Color(0xFF1D1D1D);
const Color kCardColor = Color(0xFF282A18);

// Placeholder for FirebaseFirestore instance
final _firestore = FirebaseFirestore.instance;

class Events extends StatefulWidget {
  const Events({super.key});
  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  // ... (Events State and methods remain unchanged as they correctly display events)

  String selectedSport = 'All';
  final List<String> sports = ['All', 'Cricket', 'Football', 'Tennis', 'Chess'];

  final Map<String, String> sportCollection = {
    'Cricket': 'crickethost',
    'Football': 'footballhost',
    'Tennis': 'tabletennishost',
    'Chess': 'chesshost',
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.5, -0.7),
            end: Alignment(0.5, 1.0),
            colors: [Color(0xFF525832), Color(0xFF282A18), Color(0xFF1D1D1D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Discover events nearby",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              // sport filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: sports.map((sport) {
                    final isSelected = sport == selectedSport;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(sport),
                        selected: isSelected,
                        selectedColor: const Color(0xFFA9BC4B),
                        backgroundColor: const Color(0xFF000000),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() => selectedSport = sport);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildEventsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (selectedSport == 'All') {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: sportCollection.entries.map((entry) {
          final coll = entry.value;
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(coll)
                .where('status', isEqualTo: 'open')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snap.data!.docs
                    .map((d) => _buildEventCardFromDoc(coll, d))
                    .toList(),
              );
            },
          );
        }).toList(),
      );
    } else {
      final coll = sportCollection[selectedSport]!;
      return StreamBuilder<QuerySnapshot>(
        stream:
        _firestore.collection(coll).where('status', isEqualTo: 'open').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('No events found',
                    style: TextStyle(color: Colors.white70)));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs.map((d) => _buildEventCardFromDoc(coll, d)).toList(),
          );
        },
      );
    }
  }

  Widget _buildEventCardFromDoc(String collection, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final eventName = (data['eventName'] ?? 'Untitled') as String;
    final date = (data['date'] ?? '') as String;
    final time = (data['time'] ?? '') as String;
    final slots = (data['teamSlots'] is int)
        ? data['teamSlots'] as int
        : int.tryParse(data['teamSlots']?.toString() ?? '0') ??
        (data['numPlayers'] is int ? data['numPlayers'] : 0);
    final registered = (data['registeredTeamsCount'] is int)
        ? data['registeredTeamsCount'] as int
        : int.tryParse(data['registeredTeamsCount']?.toString() ?? '0') ?? 0;
    final slotsLeft = (slots - registered) < 0 ? 0 : (slots - registered);

    final isTeamGame = collection.contains('football') || collection.contains('cricket');

    return Card(
      color: const Color(0xFF000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(eventName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isTeamGame ? 'Teams left' : 'Slots left',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                        color: slotsLeft > 0 ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('$slotsLeft',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (date.isNotEmpty)
            Text(date, style: const TextStyle(color: Colors.white70)),
          if (time.isNotEmpty)
            Text(time, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA9BC4B)),
            onPressed: slotsLeft > 0
                ? () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => JoinPage(
                    collection: collection,
                    eventDocId: doc.id,
                    eventTitle: eventName,
                    // Pass total number of players required for the team/solo game
                    playersPerTeam: data['playersPerTeam'] is int
                        ? data['playersPerTeam'] as int
                        : 1, // Default to 1 if not found
                  )));
            }
                : null,
            child: const Text('Register Now',
                style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

/// ==========================================================
/// JOIN PAGE (DYNAMIC REGISTRATION FORM)
/// ==========================================================
class JoinPage extends StatefulWidget {
  final String collection;
  final String eventDocId;
  final String eventTitle;
  final int playersPerTeam; // e.g., 6 for cricket, 1 for chess/TT

  const JoinPage({
    super.key,
    required this.collection,
    required this.eventDocId,
    required this.eventTitle,
    required this.playersPerTeam,
  });

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class PlayerDetail {
  TextEditingController fullNameCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController ageCtrl = TextEditingController();
}

class _JoinPageState extends State<JoinPage> {
  final _formKey = GlobalKey<FormState>();

  // List of controllers for all required players
  late List<PlayerDetail> playerDetails;

  bool _loading = false;
  bool _isRegistered = false;
  String _statusMessage = 'Checking registration status...';

  bool get isTeamGame => widget.playersPerTeam > 1;

  @override
  void initState() {
    super.initState();

    // Initialize controller list based on playersPerTeam
    playerDetails = List.generate(widget.playersPerTeam, (_) => PlayerDetail());

    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _statusMessage = 'Please log in to register.');
      return;
    }

    final regCollection = '${widget.collection}_registration';

    try {
      // Check for an existing registration by the current user for this event
      final snapshot = await _firestore
          .collection(regCollection)
          .where('hostDocId', isEqualTo: widget.eventDocId)
          .where('registeredByUserId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        if (mounted) setState(() {
          _isRegistered = true;
          _statusMessage = 'You have already joined this event.';
        });
      } else {
        // Prefill CAPTAIN/SOLO player details from user profile
        final userDoc = await firebaseService.fetchUserProfile(currentUser.uid);
        if (userDoc != null) {
          playerDetails[0].fullNameCtrl.text = userDoc['fullname'] ?? '';
          playerDetails[0].emailCtrl.text = userDoc['email'] ?? '';
          playerDetails[0].phoneCtrl.text = userDoc['phone'] ?? '';
          playerDetails[0].ageCtrl.text = userDoc['age'] ?? '';
        }
        if (mounted) setState(() => _statusMessage = 'Ready to register.');
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Error checking status.');
      print('Error checking registration status: $e');
    }
  }

  @override
  void dispose() {
    for (var pd in playerDetails) {
      pd.fullNameCtrl.dispose();
      pd.phoneCtrl.dispose();
      pd.emailCtrl.dispose();
      pd.ageCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegistered) return;

    setState(() => _loading = true);

    try {
      // Map all player details for storage
      final List<Map<String, dynamic>> players = playerDetails.asMap().entries.map((entry) {
        final index = entry.key;
        final detail = entry.value;
        return {
          'index': index,
          'role': index == 0 ? (isTeamGame ? 'Captain' : 'Solo Player') : 'Player ${index + 1}',
          'fullName': detail.fullNameCtrl.text.trim(),
          'phone': detail.phoneCtrl.text.trim(),
          'email': detail.emailCtrl.text.trim(),
          'age': detail.ageCtrl.text.trim(),
        };
      }).toList();

      await firebaseService.registerForEvent(
        '${widget.collection}_registration',
        {
          'hostDocId': widget.eventDocId,
          'eventTitle': widget.eventTitle,
          'teamName': isTeamGame ? playerDetails[0].fullNameCtrl.text.trim() : 'N/A', // Team name as Captain's name (simple approach)
          'totalPlayers': widget.playersPerTeam,
          'players': players, // Store the list of players
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Slot reduced.')));

      if(mounted) {
        setState(() {
          _isRegistered = true;
          _statusMessage = 'Registration complete!';
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: kDarkBackground,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTeamGame ? 'Team Registration' : 'Solo Registration',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Check / Loader / Registered Message
                    if (_loading || _statusMessage == 'Checking registration status...')
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: kAccentColor),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isRegistered ? kAccentColor : Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Registration Form
                    if (!_isRegistered)
                      Form(
                        key: _formKey,
                        child: Column(children: [

                          // Dynamically generate player input fields
                          ...List.generate(widget.playersPerTeam, (index) {
                            final playerRole = index == 0
                                ? (isTeamGame ? 'Captain Details' : 'Solo Player Details')
                                : 'Player ${index + 1} Details';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0) const Divider(color: Colors.white38, height: 30),
                                Text(
                                  playerRole,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: index == 0 ? kAccentColor : Colors.white70,
                                    fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildThemedTextFormField(playerDetails[index].fullNameCtrl, 'Full Name'),
                                _buildThemedTextFormField(playerDetails[index].phoneCtrl, 'Phone Number', keyboard: TextInputType.phone),
                                _buildThemedTextFormField(playerDetails[index].emailCtrl, 'Email Address', keyboard: TextInputType.emailAddress),
                                _buildThemedTextFormField(playerDetails[index].ageCtrl, 'Age', keyboard: TextInputType.number),
                              ],
                            );
                          }),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccentColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _submit,
                              child: _loading
                                  ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
                                  : Text(
                                isTeamGame ? 'Register Team (${widget.playersPerTeam})' : 'Register Solo',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ]),
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

  Widget _buildThemedTextFormField(TextEditingController controller, String labelText, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: kAccentColor, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return '$labelText required';
            if (keyboard == TextInputType.emailAddress && !v.contains('@')) return 'Enter a valid email';
            if (keyboard == TextInputType.phone && v.length < 10) return 'Invalid phone number';
            return null;
          }
      ),
    );
  }
}