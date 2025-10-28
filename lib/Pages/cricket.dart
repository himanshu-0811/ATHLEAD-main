// cricket.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for hostUserId
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'home.dart';

class CricketHost extends StatefulWidget {
  final String bookingId;
  final String turfId;
  final String turfName;
  final String date; // yyyy-mm-dd
  final List<String> reservedSlots;

  const CricketHost({
    super.key,
    required this.bookingId,
    required this.turfId,
    required this.turfName,
    required this.date,
    required this.reservedSlots,
  });

  @override
  State<CricketHost> createState() => _CricketHostState();
}

class _CricketHostState extends State<CricketHost> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _event = TextEditingController();
  final TextEditingController _teams = TextEditingController(text: '16');
  final TextEditingController _players = TextEditingController(text: '16');
  final TextEditingController _overs = TextEditingController(text: '5');
  final TextEditingController _location = TextEditingController();

  TimeOfDay? _reportTime;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _location.text = widget.turfName;
  }

  @override
  void dispose() {
    for (final c in [_event, _teams, _players, _overs, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickReportTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted) return;
    if (picked != null) setState(() => _reportTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Must be logged in to host.")));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _creating = true;
      _error = null;
    });

    final eventName = _event.text.trim();
    final teamSlots = int.tryParse(_teams.text.trim()) ?? 0;
    final playersPerTeam = int.tryParse(_players.text.trim()) ?? 0;
    final oversPerSide = int.tryParse(_overs.text.trim()) ?? 0;

    if (teamSlots <= 0 || playersPerTeam <= 0 || oversPerSide <= 0) {
      setState(() {
        _creating = false;
        _error = 'Enter valid numeric values.';
      });
      messenger.showSnackBar(const SnackBar(content: Text('Enter valid numeric values')));
      return;
    }

    try {
      String station = '';
      String turfAddress = '';
      if (widget.bookingId.isNotEmpty) {
        final bdata = await firebaseService.fetchBookingDetails(widget.bookingId);
        if (bdata != null) {
          station = (bdata['station'] ?? '').toString();
          turfAddress = (bdata['turfAddress'] ?? '').toString();
        }
      }

      final doc = <String, dynamic>{
        'bookingId': widget.bookingId,
        'turfId': widget.turfId,
        'turfName': widget.turfName,
        'sport': 'Cricket',
        'date': widget.date,
        'reservedSlots': widget.reservedSlots,
        'reportTime': _reportTime != null ? _reportTime!.format(context) : '',
        'oversPerSide': oversPerSide,
        'teamSlots': teamSlots,
        'playersPerTeam': playersPerTeam,
        'registeredTeamsCount': 0,
        'status': 'open',
        'location': _location.text.trim(),
        'station': station,
        'turfAddress': turfAddress,
        'eventName': eventName,
        'notes': '',

        'hostUserId': currentUserId, // CRUCIAL: Link event to the host

        'createdAt': FieldValue.serverTimestamp(), // Use actual timestamp
        'updatedAt': FieldValue.serverTimestamp(), // Use actual timestamp
      };

      await firebaseService.createHostEvent('crickethost', doc);

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Cricket event created successfully')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AndroidCompact2()));
    } catch (e) {
      debugPrint('Error creating crickethost: $e');
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = 'Failed to create event: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create event: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (unchanged build method)
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ensure this asset exists
            Image.asset('assets/cric.jpg', fit: BoxFit.cover),
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
                          Text('Host Cricket Event',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                          const SizedBox(height: 16),

                          Card(
                            color: Colors.black54,
                            child: ListTile(
                              title: Text(widget.turfName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('Date: ${widget.date}\nReserved: ${widget.reservedSlots.join(', ')}',
                                  style: const TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _event,
                            decoration: const InputDecoration(labelText: 'Event name', labelStyle: TextStyle(color: Colors.white)),
                            style: const TextStyle(color: Colors.white),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _teams,
                                  decoration: const InputDecoration(labelText: 'Total number of teams', labelStyle: TextStyle(color: Colors.white)),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(color: Colors.white),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _players,
                                  decoration: const InputDecoration(labelText: 'Players per team', labelStyle: TextStyle(color: Colors.white)),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(color: Colors.white),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) return 'Required';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _overs,
                            decoration: const InputDecoration(labelText: 'Overs per side (e.g. 20)', labelStyle: TextStyle(color: Colors.white)),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) return 'Required';
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _location,
                            decoration: const InputDecoration(labelText: 'Location', labelStyle: TextStyle(color: Colors.white)),
                            style: const TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(child: Text(_reportTime == null ? 'Select report time' : 'Report time: ${_reportTime!.format(context)}', style: const TextStyle(color: Colors.white))),
                              ElevatedButton(onPressed: _pickReportTime, child: const Text('Pick')),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),

                          const SizedBox(height: 12),

                          _creating ? const CircularProgressIndicator() : ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF525832)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                              child: Text('Create Cricket Event'),
                            ),
                          ),
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
    );
  }
}