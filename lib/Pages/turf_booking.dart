// turf_booking_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// host screens - adjust paths if these files are inside folders
import 'football.dart';
import 'cricket.dart';

class TurfBookingPage extends StatefulWidget {
  final String sportName;
  const TurfBookingPage({super.key, required this.sportName});

  @override
  State<TurfBookingPage> createState() => _TurfBookingPageState();
}

class _TurfBookingPageState extends State<TurfBookingPage> {
  // UI selections
  String? selectedZone;
  String? selectedStation;
  DateTime? selectedDate;
  String? selectedTurfId;
  String? selectedTurfName;

  // multi-slot selection
  List<String> selectedTimeSlots = [];

  // data lists loaded from Firestore
  List<String> zones = [];
  List<String> stations = [];
  List<Map<String, dynamic>> turfsForStation = []; // list of maps {id, name, ...}

  // booking-related
  List<String> timeSlots = [
    "7 AM - 9 AM",
    "9 AM - 11 AM",
    "11 AM - 1 PM",
    "1 PM - 3 PM",
    "3 PM - 5 PM",
    "5 PM - 7 PM",
    "7 PM - 9 PM",
    "9 PM - 11 PM",
  ];
  Set<String> bookedSlotsForSelected = {}; // slots already booked for selected turf+date

  bool _loadingZones = true;
  bool _loadingStations = false;
  bool _loadingTurfs = false;
  bool _loadingBookedSlots = false;
  bool _creatingBooking = false;
  String? _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  // Load unique zones from turfs collection
  Future<void> _loadZones() async {
    setState(() {
      _loadingZones = true;
    });
    try {
      final snapshot = await _firestore.collection('turfs').get();
      final Set<String> zoneSet = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final z = (data['zone'] ?? '').toString();
        if (z.isNotEmpty) zoneSet.add(z);
      }
      setState(() {
        zones = zoneSet.toList()..sort();
      });
    } catch (e) {
      debugPrint('Error loading zones: $e');
      setState(() => _errorMessage = 'Error loading zones');
    } finally {
      setState(() => _loadingZones = false);
    }
  }

  // Load unique stations for chosen zone
  Future<void> _loadStationsForZone(String zone) async {
    setState(() {
      _loadingStations = true;
      stations = [];
      selectedStation = null;
      turfsForStation = [];
      selectedTurfId = null;
      selectedTurfName = null;
      selectedDate = null;
      selectedTimeSlots.clear();
      bookedSlotsForSelected.clear();
    });

    try {
      final q = await _firestore.collection('turfs').where('zone', isEqualTo: zone).get();
      final Set<String> stationSet = {};
      for (final doc in q.docs) {
        final d = doc.data();
        final st = (d['station'] ?? '').toString();
        if (st.isNotEmpty) stationSet.add(st);
      }
      final list = stationSet.toList()..sort();
      setState(() {
        stations = list;
      });
    } catch (e) {
      debugPrint('Error loading stations: $e');
      setState(() => _errorMessage = 'Error loading stations');
    } finally {
      setState(() => _loadingStations = false);
    }
  }

  // Load turfs (documents) for chosen station
  Future<void> _loadTurfsForStation(String station) async {
    setState(() {
      _loadingTurfs = true;
      turfsForStation = [];
      selectedTurfId = null;
      selectedTurfName = null;
      selectedDate = null;
      selectedTimeSlots.clear();
      bookedSlotsForSelected.clear();
    });

    try {
      final q = await _firestore.collection('turfs').where('station', isEqualTo: station).get();
      final List<Map<String, dynamic>> list = [];
      for (final doc in q.docs) {
        final data = doc.data();
        list.add({
          'id': doc.id,
          'name': (data['name'] ?? data['turfName'] ?? '').toString(),
          'capacity': data['capacity'] ?? 1,
          'contact': data['contact'] ?? '',
          'address': data['address'] ?? '',
          'zone': data['zone'] ?? '',
          'station': data['station'] ?? '',
        });
      }
      // sort by name
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      setState(() {
        turfsForStation = list;
      });
    } catch (e) {
      debugPrint('Error loading turfs for station: $e');
      setState(() => _errorMessage = 'Error loading turfs');
    } finally {
      setState(() => _loadingTurfs = false);
    }
  }

  // Fetch booked slots for selected turf and date
  Future<void> _fetchBookedSlotsForSelectedTurfAndDate() async {
    if (selectedTurfId == null || selectedDate == null) {
      setState(() => bookedSlotsForSelected = {});
      return;
    }

    setState(() {
      _loadingBookedSlots = true;
      bookedSlotsForSelected = {};
    });

    try {
      final dateStr = _dateToKey(selectedDate!); // e.g. 2025-09-07
      final q = await _firestore
          .collection('bookings')
          .where('turfId', isEqualTo: selectedTurfId)
          .where('date', isEqualTo: dateStr)
          .get();

      final Set<String> booked = {};
      for (final doc in q.docs) {
        final data = doc.data();
        final ts = data['timeSlots'];
        if (ts is List) {
          for (final s in ts) {
            if (s != null) booked.add(s.toString());
          }
        } else if (ts is String) {
          booked.add(ts);
        }
      }

      setState(() {
        bookedSlotsForSelected = booked;
        // If any previously selected slots became booked in the meantime, remove them
        selectedTimeSlots.removeWhere((s) => booked.contains(s));
      });
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
      setState(() => _errorMessage = 'Error loading bookings');
    } finally {
      setState(() => _loadingBookedSlots = false);
    }
  }

  // helper: format date to simple key string
  String _dateToKey(DateTime d) {
    // yyyy-mm-dd
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  // create booking in firestore; returns bookingId on success, null on failure
  Future<String?> _createBooking() async {
    if (selectedTurfId == null || selectedDate == null || selectedTimeSlots.isEmpty) {
      setState(() => _errorMessage = 'Select turf, date and at least one time slot');
      return null;
    }

    setState(() {
      _creatingBooking = true;
      _errorMessage = null;
    });

    try {
      final dateKey = _dateToKey(selectedDate!);

      // 1) fetch existing bookings for this turf & date
      final q = await _firestore
          .collection('bookings')
          .where('turfId', isEqualTo: selectedTurfId)
          .where('date', isEqualTo: dateKey)
          .get();

      final Set<String> existing = {};
      for (final doc in q.docs) {
        final data = doc.data();
        final ts = data['timeSlots'];
        if (ts is List) {
          for (final s in ts) {
            if (s != null) existing.add(s.toString());
          }
        } else if (ts is String) {
          existing.add(ts);
        }
      }

      // 2) check conflicts
      final conflicts = selectedTimeSlots.where((s) => existing.contains(s)).toList();
      if (conflicts.isNotEmpty) {
        setState(() {
          _creatingBooking = false;
          _errorMessage = 'Slot(s) just booked by someone else: ${conflicts.join(", ")}';
        });

        // show snack bar (use context AFTER we've set state, no context captured before async)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage!)),
          );
        }

        // refresh booked slots UI
        await _fetchBookedSlotsForSelectedTurfAndDate();
        return null;
      }

      // 3) write new booking and capture id
      final bookingDoc = <String, dynamic>{
        'turfId': selectedTurfId,
        'turfName': selectedTurfName ?? '',
        'sport': widget.sportName,
        'zone': selectedZone ?? '',
        'station': selectedStation ?? '',
        'date': dateKey,
        'timeSlots': selectedTimeSlots,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final ref = await _firestore.collection('bookings').add(bookingDoc);
      final bookingId = ref.id;

      // update UI: treat these slots as booked now
      setState(() {
        bookedSlotsForSelected.addAll(selectedTimeSlots);
        selectedTimeSlots.clear();
        _creatingBooking = false;
      });

      if (!mounted) return bookingId;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking created successfully')));

      return bookingId;
    } catch (e) {
      debugPrint('Booking creation error: $e');
      setState(() {
        _creatingBooking = false;
        _errorMessage = 'Booking failed: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
      return null;
    }
  }

  // NEW: navigate to appropriate host screen based on sportName
  void _navigateToHost(String bookingId, List<String> reservedSlots) {
    if (!mounted) return;

    final sport = widget.sportName.trim().toLowerCase();
    final turfId = selectedTurfId!;
    final turfName = selectedTurfName ?? '';
    final dateKey = _dateToKey(selectedDate!);

    Widget destination;

    if (sport.contains('football')) {
      destination = FootballHost(
        bookingId: bookingId,
        turfId: turfId,
        turfName: turfName,
        date: dateKey,
        reservedSlots: reservedSlots,
      );
    } else if (sport.contains('cricket')) {
      destination = CricketHost(
        bookingId: bookingId,
        turfId: turfId,
        turfName: turfName,
        date: dateKey,
        reservedSlots: reservedSlots,
      );
    }  else {
      // fallback: show snackbar and open FootballHost as default
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No specific host screen for "${widget.sportName}". Opening generic host.')));
      destination = FootballHost(
        bookingId: bookingId,
        turfId: turfId,
        turfName: turfName,
        date: dateKey,
        reservedSlots: reservedSlots,
      );
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  // UI helpers
  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.black26,
      ),
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    // keep your gradient background
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  "Book Turf for ${widget.sportName}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Zones dropdown (loaded from turfs collection)
                _loadingZones
                    ? const Center(child: CircularProgressIndicator())
                    : _buildDropdown<String>(
                  label: 'Select Zone',
                  value: selectedZone,
                  items: zones
                      .map((z) => DropdownMenuItem(
                    value: z,
                    child: Text(z, style: const TextStyle(color: Colors.white)),
                  ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      selectedZone = v;
                      selectedStation = null;
                      stations = [];
                      turfsForStation = [];
                      selectedTurfId = null;
                      selectedTurfName = null;
                      selectedDate = null;
                      selectedTimeSlots.clear();
                      bookedSlotsForSelected.clear();
                    });
                    _loadStationsForZone(v);
                  },
                ),
                const SizedBox(height: 16),

                // Station dropdown
                if (_loadingStations)
                  const Center(child: CircularProgressIndicator())
                else if (selectedZone != null)
                  _buildDropdown<String>(
                    label: 'Select Station',
                    value: selectedStation,
                    items: stations
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        selectedStation = v;
                        selectedTurfId = null;
                        selectedTurfName = null;
                        turfsForStation = [];
                        selectedDate = null;
                        selectedTimeSlots.clear();
                        bookedSlotsForSelected.clear();
                      });
                      _loadTurfsForStation(v);
                    },
                  ),

                const SizedBox(height: 16),

                // Date picker (only when station chosen)
                if (selectedStation != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF525832),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              selectedTurfId = null;
                              selectedTurfName = null;
                              selectedTimeSlots.clear();
                              bookedSlotsForSelected.clear();
                            });
                          }
                        },
                        child: const Text("Pick Date"),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Turf dropdown (load from turfsForStation)
                if (_loadingTurfs)
                  const Center(child: CircularProgressIndicator())
                else if (selectedDate != null && selectedStation != null)
                  _buildDropdown<String>(
                    label: 'Select Turf',
                    value: selectedTurfId,
                    items: turfsForStation
                        .map((t) => DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text((t['name'] ?? '') as String, style: const TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      final turfMap = turfsForStation.firstWhere((t) => t['id'] == value, orElse: () => <String, dynamic>{});
                      setState(() {
                        selectedTurfId = value;
                        selectedTurfName = (turfMap['name'] ?? '').toString();
                        selectedTimeSlots.clear();
                        bookedSlotsForSelected.clear();
                      });
                      // fetch booked slots for new turf & date
                      await _fetchBookedSlotsForSelectedTurfAndDate();
                    },
                  ),

                const SizedBox(height: 20),

                // Time Slots UI
                if (selectedTurfId != null) ...[
                  const Text(
                    "Select Time Slots:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _loadingBookedSlots
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = timeSlots[index];
                      final isBooked = bookedSlotsForSelected.contains(slot);
                      final isSelected = selectedTimeSlots.contains(slot);

                      Color bgColor;
                      Color textColor;
                      if (isBooked) {
                        bgColor = Colors.red;
                        textColor = Colors.white;
                      } else if (isSelected) {
                        bgColor = Colors.green;
                        textColor = Colors.white;
                      } else {
                        bgColor = Colors.white;
                        textColor = Colors.black;
                      }

                      return GestureDetector(
                        onTap: isBooked
                            ? null
                            : () {
                          setState(() {
                            if (isSelected) {
                              selectedTimeSlots.remove(slot);
                            } else {
                              selectedTimeSlots.add(slot);
                            }
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Text(
                            slot,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Create booking button
                _creatingBooking
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF525832),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: (selectedZone != null &&
                      selectedStation != null &&
                      selectedDate != null &&
                      selectedTurfId != null &&
                      selectedTimeSlots.isNotEmpty)
                      ? () async {
                    // capture the selected slots locally before booking (we'll pass them to host)
                    final reservedSlots = List<String>.from(selectedTimeSlots);

                    final bookingId = await _createBooking();
                    if (bookingId == null) return; // booking failed

                    if (!mounted) return;

                    // navigate to appropriate host screen
                    _navigateToHost(bookingId, reservedSlots);
                  }
                      : null,
                  child: const Text("Host"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
