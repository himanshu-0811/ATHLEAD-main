// tabletennis.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for hostUserId
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'home.dart';

class TableTennis extends StatefulWidget {
  final String bookingId;
  final String turfId;
  final String turfName;
  final String date; // yyyy-mm-dd
  final List<String> reservedSlots;

  const TableTennis({
    super.key,
    this.bookingId = '',
    this.turfId = '',
    this.turfName = '',
    this.date = '',
    this.reservedSlots = const [],
  });

  @override
  State<TableTennis> createState() => _TableTennisState();
}

class _TableTennisState extends State<TableTennis> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _event = TextEditingController();
  final TextEditingController _time = TextEditingController();
  final TextEditingController _players = TextEditingController();

  String? _selectedMode;
  String? _selectedGameTime;

  final Map<String, List<String>> _gameTimes = {
    'Singles': ['11 pts', '15 pts'],
  };

  // UI step flags
  bool _showTime = false;
  bool _showMode = false;
  bool _showGameTime = false;
  bool _showPlayers = false;
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
          _showPlayers = false;
          _showSubmit = false;
          _selectedMode = null;
          _selectedGameTime = null;
          _time.clear();
          _players.clear();
        });
      }
    });

    _players.addListener(() {
      final hasPlayers = _players.text.trim().isNotEmpty;
      if (hasPlayers && !_showSubmit) {
        setState(() => _showSubmit = true);
      } else if (!hasPlayers && _showSubmit) {
        setState(() => _showSubmit = false);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_event, _time, _players]) {
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
    final playersText = _players.text.trim();
    final numPlayers = int.tryParse(playersText);

    if (numPlayers == null || numPlayers <= 0) {
      setState(() => _errorMessage = 'Enter a valid number of players');
      return;
    }

    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    try {
      final playersPerEntry = (gameMode.toLowerCase().contains('double')) ? 2 : 1;

      final doc = <String, dynamic>{
        'bookingId': widget.bookingId,
        'turfId': widget.turfId,
        'turfName': widget.turfName,
        'sport': 'Tennis',
        'date': widget.date,
        'reservedSlots': widget.reservedSlots,
        'time': timeText,
        'gameMode': gameMode,
        'gameDuration': gameDuration,
        'numPlayers': numPlayers,
        'slots': numPlayers,
        'teamSlots': numPlayers,
        'playersPerTeam': playersPerEntry,
        'status': 'open',
        'eventName': eventName,
        'notes': '',
        'registeredTeamsCount': 0,

        'hostUserId': currentUserId, // CRUCIAL: Link event to the host

        'createdAt': FieldValue.serverTimestamp(), // Use actual timestamp
        'updatedAt': FieldValue.serverTimestamp(), // Use actual timestamp
      };

      await firebaseService.createHostEvent('tabletennishost', doc);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Table Tennis event created successfully')),
      );

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AndroidCompact2()));
    } catch (e) {
      debugPrint('Failed to create table tennis event: $e');
      if (!mounted) return;
      setState(() {
        _creating = false;
        _errorMessage = 'Failed to create event';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create event: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (unchanged build method)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
      home: Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset('assets/tennis.jpg', fit: BoxFit.cover), // Ensure asset exists
              Container(color: Colors.black.withOpacity(0.8), child: const Center(child: Text(" ", style: TextStyle(color: Colors.white, fontSize: 30)))),
              Container(color: Colors.black.withOpacity(0.35)),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Table Tennis',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                            const SizedBox(height: 16),

                            // Card showing turfName/date/reservedSlots (if present)
                            Card(
                              color: Colors.black54,
                              child: ListTile(
                                title: Text(widget.turfName.isNotEmpty ? widget.turfName : 'Table Tennis Venue',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Date: ${widget.date.isNotEmpty ? widget.date : '-'}\nReserved: ${widget.reservedSlots.isNotEmpty ? widget.reservedSlots.join(', ') : '-'}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Event name (first field) - typing reveals Time
                            _buildText('Event', _event),

                            const SizedBox(height: 12),

                            // Time picker (revealed after event name)
                            if (_showTime) ...[
                              GestureDetector(
                                onTap: () => _selectTime(context),
                                child: AbsorbPointer(
                                  child: _buildText('Time', _time, validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    return null;
                                  }),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Game mode (revealed after picking time)
                            if (_showMode) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedMode,
                                decoration: const InputDecoration(
                                  labelText: 'Game Mode',
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.yellow),
                                  ),
                                ),
                                dropdownColor: Colors.black,
                                style: const TextStyle(color: Colors.white),
                                items: _gameTimes.keys
                                    .map<DropdownMenuItem<String>>((mode) => DropdownMenuItem<String>(
                                  value: mode,
                                  child: Text(mode),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMode = value;
                                    _selectedGameTime = null;
                                    _showGameTime = value != null;
                                    _showPlayers = false;
                                    _showSubmit = false;
                                    _players.clear();
                                  });
                                },
                                validator: (value) => value == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Game time (depends on mode)
                            if (_showGameTime && _selectedMode != null) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedGameTime,
                                decoration: const InputDecoration(
                                  labelText: 'Game Time',
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.yellow),
                                  ),
                                ),
                                dropdownColor: Colors.black,
                                style: const TextStyle(color: Colors.white),
                                items: _gameTimes[_selectedMode]!
                                    .map<DropdownMenuItem<String>>((time) => DropdownMenuItem<String>(
                                  value: time,
                                  child: Text(time),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGameTime = value;
                                    _showPlayers = value != null;
                                    if (_players.text.trim().isNotEmpty) _showSubmit = true;
                                  });
                                },
                                validator: (value) => value == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Number of players (host-specified slots)
                            if (_showPlayers) ...[
                              _buildText(
                                'No of players',
                                _players,
                                keyboard: TextInputType.number,
                                formatterDigitsOnly: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final n = int.tryParse(v);
                                  if (n == null || n <= 0) return 'Enter valid number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                            ],

                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              ),

                            _creating
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF525832),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                              ),
                              onPressed: _showSubmit && !_creating ? _createEvent : null,
                              child: const Text('Submit'),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText(
      String label,
      TextEditingController ctrl, {
        TextInputType keyboard = TextInputType.text,
        bool formatterDigitsOnly = false,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: formatterDigitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.yellow),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
