// join.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID
import 'registration.dart';
import 'firebase_service.dart';

// Placeholder for FirebaseFirestore instance
final _firestore = FirebaseFirestore.instance;

class Events extends StatefulWidget {
  final String? initialSport;
  const Events({super.key, this.initialSport});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  // ... (Events State, build methods, and _buildEventsList remain unchanged)

  late String selectedSport;
  final List<String> sports = ['All', 'Cricket', 'Football', 'Tennis', 'Chess'];

  final Map<String, String> sportCollection = {
    'Cricket': 'crickethost',
    'Football': 'footballhost',
    'Tennis': 'tabletennishost',
    'Chess': 'chesshost',
  };

  @override
  void initState() {
    super.initState();
    final init = widget.initialSport != null && sports.contains(widget.initialSport)
        ? widget.initialSport!
        : 'All';
    selectedSport = init;
  }

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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
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
            stream: _firestore.collection(coll).where('status', isEqualTo: 'open').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return const SizedBox();
              if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snap.data!.docs.map((d) => _buildEventCardFromDoc(coll, d)).toList(),
              );
            },
          );
        }).toList(),
      );
    } else {
      final coll = sportCollection[selectedSport] ?? (selectedSport.toLowerCase() + 'host');
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(coll).where('status', isEqualTo: 'open').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No events found', style: TextStyle(color: Colors.white70)),
            );
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
    final eventName = (data['eventName'] ?? data['title'] ?? data['name'] ?? 'Untitled') as String;
    final date = (data['date'] ?? '') as String;
    final time = (data['time'] ?? data['timeSlot'] ?? '') as String;

    final teamSlots = (data['teamSlots'] is int) ? data['teamSlots'] as int : int.tryParse((data['teamSlots'] ?? '').toString()) ?? 0;
    final legacySlots = (data['numPlayers'] is int) ? data['numPlayers'] as int : (data['slots'] is int ? data['slots'] as int : 0);
    final slotsTotal = teamSlots > 0 ? teamSlots : legacySlots;
    final registered = (data['registeredTeamsCount'] is int) ? data['registeredTeamsCount'] as int : int.tryParse((data['registeredTeamsCount'] ?? '').toString()) ?? 0;
    final slotsLeft = (slotsTotal - registered) < 0 ? 0 : (slotsTotal - registered);
    final rules = (data['rules'] ?? '') as String;

    final stationFromHost = (data['station'] ?? data['stationName'] ?? data['station_name'] ?? '') as String;
    final turfAddressFromHost = (data['turfAddress'] ?? data['address'] ?? '') as String;

    final isTeamGame = collection.contains('football') || collection.contains('cricket');
    final playersPerTeam = isTeamGame ? (data['playersPerTeam'] is int ? data['playersPerTeam'] as int : 11) : 1;

    final bookingId = (data['bookingId'] ?? '') as String;

    // Use a FutureBuilder to check booking details/location only if needed
    final locationFuture = bookingId.isNotEmpty
        ? firebaseService.fetchBookingDetails(bookingId)
        : Future.value(null);

    return FutureBuilder<Map<String, dynamic>?>(
      future: locationFuture,
      builder: (context, snap) {
        String station = stationFromHost;
        String address = turfAddressFromHost;
        String bookingReportTime = '';
        if (snap.hasData && snap.data != null) {
          final bdata = snap.data!;
          station = (bdata['station'] ?? bdata['stationName'] ?? bdata['station_name'] ?? '') as String;
          address = (bdata['turfAddress'] ?? bdata['address'] ?? '') as String;
          bookingReportTime = (bdata['reportTime'] ?? bdata['report_time'] ?? '') as String;
        }
        final effectiveReportTime = (data['reportTime'] ?? '') as String;
        final reportTime = effectiveReportTime.isNotEmpty ? effectiveReportTime : bookingReportTime;

        return _EventCard(
          collection: collection,
          docId: doc.id,
          eventName: eventName,
          date: date,
          time: time,
          reportTime: reportTime,
          station: station,
          turfAddress: address,
          rules: rules,
          slotsLeft: slotsLeft,
          teamSlots: slotsTotal,
          playersPerTeam: playersPerTeam,
        );
      },
    );
  }
}

class _EventCard extends StatefulWidget {
  final String collection;
  final String docId;
  final String eventName;
  final String date;
  final String time;
  final String reportTime;
  final String station;
  final String turfAddress;
  final String rules;
  final int slotsLeft;
  final int teamSlots;
  final int playersPerTeam;

  const _EventCard({
    required this.collection,
    required this.docId,
    required this.eventName,
    required this.date,
    required this.time,
    required this.reportTime,
    required this.station,
    required this.turfAddress,
    required this.rules,
    required this.slotsLeft,
    required this.teamSlots,
    required this.playersPerTeam,
    // Removed onRegister as the button logic is complex now
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _showDetails = false;
  // State variables for dynamic button:
  bool _isCheckingStatus = true;
  DocumentSnapshot? _registrationDoc; // Stores the registration doc if found

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (currentUserId != null) {
      _checkRegistrationStatus();
    } else {
      _isCheckingStatus = false;
    }
  }

  Future<void> _checkRegistrationStatus() async {
    final regCollection = '${widget.collection}_registration';
    if (currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection(regCollection)
          .where('hostDocId', isEqualTo: widget.docId)
          .where('registeredByUserId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          if (snapshot.docs.isNotEmpty) {
            _registrationDoc = snapshot.docs.first;
          } else {
            _registrationDoc = null;
          }
        });
      }
    } catch (e) {
      print('Error checking registration status: $e');
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  // --- HANDLERS ---

  void _navigateToRegistration() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JoinPage(
        collection: widget.collection,
        eventDocId: widget.docId,
        eventTitle: widget.eventName,
        playersPerTeam: widget.playersPerTeam,
      ),
    )).then((value) {
      // Refresh status when returning from registration page
      _checkRegistrationStatus();
    });
  }

  Future<void> _handleCancelRegistration() async {
    if (_registrationDoc == null) return;

    // 1. Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282A18),
        title: const Text('Cancel Registration'),
        content: const Text('Are you sure you wish to cancel your registration for this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCheckingStatus = true); // Use checking status as a loader

    try {
      // 2. Delete the registration record
      final regCollection = '${widget.collection}_registration';
      await _firestore.collection(regCollection).doc(_registrationDoc!.id).delete();

      // 3. Decrement the slot count on the host document
      // NOTE: Using FieldValue.increment(-1) here handles the decrement.
      await _firestore.collection(widget.collection).doc(widget.docId).update({
        'registeredTeamsCount': FieldValue.increment(-1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration cancelled successfully!')),
        );
      }
    } catch (e) {
      print('Error cancelling registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel registration: $e')),
        );
      }
    } finally {
      // 4. Refresh the UI status
      _checkRegistrationStatus();
    }
  }

  // --- WIDGET BUILDER FOR DYNAMIC BUTTON ---
  Widget _buildActionButton() {
    if (currentUserId == null) {
      return const Text("Log in to Register", style: TextStyle(color: Colors.white70));
    }

    if (_isCheckingStatus) {
      return const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB1C900))
      );
    }

    if (_registrationDoc != null) {
      // ALREADY REGISTERED STATE
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Already Registered',
            style: TextStyle(color: Color(0xFFA9BC4B), fontSize: 12),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _handleCancelRegistration,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: const Text('Cancel Registration', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }

    // AVAILABLE TO REGISTER STATE
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA9BC4B)),
      onPressed: widget.slotsLeft > 0 ? _navigateToRegistration : null,
      child: const Text('Register Now', style: TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (timeLine calculation remains the same)
    final timeLine = (() {
      if (widget.time.isNotEmpty && widget.reportTime.isNotEmpty) {
        return '${widget.time} • Report: ${widget.reportTime}';
      } else if (widget.time.isNotEmpty) {
        return widget.time;
      } else if (widget.reportTime.isNotEmpty) {
        return 'Report: ${widget.reportTime}';
      } else {
        return '';
      }
    })();

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
              Expanded(child: Text(widget.eventName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Slots left', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: widget.slotsLeft > 0 ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(6)),
                    child: Text('${widget.slotsLeft}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.date.isNotEmpty) Text(widget.date, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          if (timeLine.isNotEmpty) Text(timeLine, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          if (widget.station.isNotEmpty) Text(widget.station, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),

          // --- DYNAMIC ACTION BUTTON ROW ---
          Row(
            children: [
              Expanded(child: _buildActionButton()), // Use dynamic button
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                child: Text(_showDetails ? 'Hide details' : 'Details', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),

          if (_showDetails) ...[
            const SizedBox(height: 12),
            if (widget.turfAddress.isNotEmpty) Text('Address: ${widget.turfAddress}', style: const TextStyle(color: Colors.white70)),
            if (widget.rules.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Rules:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Text(widget.rules, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 8),
            Text('Team slots: ${widget.teamSlots}  •  Players/team: ${widget.playersPerTeam}', style: const TextStyle(color: Colors.white70)),
          ],
        ]),
      ),
    );
  }
}