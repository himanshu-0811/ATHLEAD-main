// chess.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for hostUserId
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'home.dart';

class Chess extends StatefulWidget {
  final String bookingId;
  final String turfId;
  final String turfName;
  final String date;
  final List<String> reservedSlots;

  const Chess({
    super.key,
    required this.bookingId,
    required this.turfId,
    required this.turfName,
    required this.date,
    required this.reservedSlots,
  });

  @override
  State<Chess> createState() => _ChessState();
}

class _ChessState extends State<Chess> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _event = TextEditingController();
  final TextEditingController _time = TextEditingController();
  final TextEditingController _teamSlots = TextEditingController();

  String? _selectedMode;
  String? _selectedGameTime;

  final Map<String, List<String>> _gameTimes = {
    'Bullet': ['1 min', '1|1', '2|1'],
    'Blitz': ['3 min', '3|2', '5 min'],
    'Rapid': ['10 min', '15|10', '30 min'],
  };

  bool _showTime = false;
  bool _showMode = false;
  bool _showGameTime = false;
  bool _showteamSlots = false;
  bool _showSubmit = false;

  bool _creating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _event.addListener(() {
      final hasText = _event.text.trim().isNotEmpty;
      if (hasText && !_showTime) {
        setState(() => _showTime = true);
      } else if (!hasText && _showTime) {
        setState(() {
          _showTime = false;
          _showMode = false;
          _showGameTime = false;
          _showteamSlots = false;
          _showSubmit = false;
          _selectedMode = null;
          _selectedGameTime = null;
          _time.clear();
          _teamSlots.clear();
        });
      }
    });

    _teamSlots.addListener(() {
      final hasteamSlots = _teamSlots.text.trim().isNotEmpty;
      if (hasteamSlots && !_showSubmit) {
        setState(() => _showSubmit = true);
      } else if (!hasteamSlots && _showSubmit) {
        setState(() => _showSubmit = false);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_event, _time, _teamSlots]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (!mounted) return;
    if (picked != null) {
      final formatted = picked.format(context);
      setState(() {
        _time.text = formatted;
        if (!_showMode) _showMode = true;
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMode == null || _selectedGameTime == null || _time.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Must be logged in to host.")));
      return;
    }

    final eventName = _event.text.trim();
    final timeText = _time.text.trim();
    final gameMode = _selectedMode!;
    final gameDuration = _selectedGameTime!;
    final teamSlotsText = _teamSlots.text.trim();
    final teamSlots = int.tryParse(teamSlotsText);

    if (teamSlots == null || teamSlots <= 0) {
      setState(() => _errorMessage = 'Enter a valid number of teamSlots');
      return;
    }

    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    try {
      final doc = <String, dynamic>{
        'bookingId': widget.bookingId,
        'turfId': widget.turfId,
        'turfName': widget.turfName,
        'sport': 'Chess',
        'date': widget.date,
        'reservedSlots': widget.reservedSlots,
        'eventName': eventName,
        'time': timeText,
        'gameMode': gameMode,
        'gameDuration': gameDuration,
        'teamSlots': teamSlots,
        'registeredTeamsCount': 0, // Using registeredTeamsCount for consistency
        'playersPerTeam': 1, // Solo game
        'status': 'open',
        'notes': '',

        'hostUserId': currentUserId, // CRUCIAL: Link event to the host

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firebaseService.createHostEvent('chesshost', doc);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chess event created successfully')),
      );

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AndroidCompact2()));
    } catch (e) {
      debugPrint('Failed to create chess event: $e');
      setState(() {
        _creating = false;
        _errorMessage = 'Failed to create event';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create event: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (unchanged build method)
    return Scaffold(
      appBar: AppBar(title: const Text('Chess'), backgroundColor: Colors.black),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/gambit.jpg', fit: BoxFit.cover), // Ensure asset exists
          Container(color: Colors.black.withOpacity(0.8), child: const Center(child: Text(" ", style: TextStyle(color: Colors.white, fontSize: 30)))),
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildText('Event', _event),
                    const SizedBox(height: 12),
                    if (_showTime)
                      GestureDetector(
                        onTap: () => _selectTime(context),
                        child: AbsorbPointer(child: _buildText('Time', _time)),
                      ),
                    if (_showMode) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedMode,
                        decoration: const InputDecoration(labelText: 'Game Mode'),
                        items: _gameTimes.keys
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedMode = v;
                            _selectedGameTime = null;
                            _showGameTime = v != null;
                          });
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ],
                    if (_showGameTime)
                      DropdownButtonFormField<String>(
                        value: _selectedGameTime,
                        decoration: const InputDecoration(labelText: 'Game Time'),
                        items: _gameTimes[_selectedMode]!
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedGameTime = v;
                            _showteamSlots = v != null;
                          });
                        },
                      ),
                    if (_showteamSlots)
                      _buildText('teamSlots', _teamSlots, keyboard: TextInputType.number, formatterDigitsOnly: true),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    _creating
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _showSubmit ? _createEvent : null,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildText(String label, TextEditingController c,
      {TextInputType keyboard = TextInputType.text, bool formatterDigitsOnly = false}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatterDigitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white)),
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}