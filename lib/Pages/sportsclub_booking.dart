// lib/Pages/sports_club_booking_page.dart
import 'package:flutter/material.dart';
import 'football.dart';
import 'cricket.dart';
import 'TableTennis.dart';
import 'gambit.dart';
import 'firebase_service.dart'; // New Import

class SportsClubBookingPage extends StatefulWidget {
  final String sportName;
  const SportsClubBookingPage({super.key, required this.sportName});

  @override
  State<SportsClubBookingPage> createState() => _SportsClubBookingPageState();
}

class _SportsClubBookingPageState extends State<SportsClubBookingPage> {
  // UI selections
  String? selectedZone;
  String? selectedStation;
  DateTime? selectedDate;
  String? selectedClubId;
  String? selectedClubName;

  // multi-slot selection
  List<String> selectedTimeSlots = [];

  // data lists loaded from Firestore
  List<String> zones = [];
  List<String> stations = [];
  List<Map<String, dynamic>> clubsForStation = []; // {id, name, ...}

  // booking-related
  final List<String> fallbackTimeSlots = [
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-13:00",
    "13:00-14:00",
    "14:00-15:00",
    "15:00-16:00",
    "16:00-17:00",
    "17:00-18:00",
    "18:00-19:00",
    "19:00-20:00",
    "20:00-21:00",
  ];

  Set<String> bookedSlotsForSelected = {};

  bool _loadingZones = true;
  bool _loadingStations = false;
  bool _loadingClubs = false;
  bool _loadingBookedSlots = false;
  bool _creatingBooking = false;
  String? _errorMessage;

  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Removed

  // Mock collection name for this page
  static const String _collectionName = 'sports_clubs';

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  // Load unique zones
  Future<void> _loadZones() async {
    setState(() {
      _loadingZones = true;
    });
    try {
      // Replaced Firestore call with mock service call
      final fetchedZones = await firebaseService.loadZones(_collectionName);
      setState(() {
        zones = fetchedZones;
      });
    } catch (e) {
      debugPrint('Error loading zones: $e');
      setState(() => _errorMessage = 'Error loading zones');
    } finally {
      setState(() => _loadingZones = false);
    }
  }

  // Load stations for chosen zone
  Future<void> _loadStationsForZone(String zone) async {
    setState(() {
      _loadingStations = true;
      stations = [];
      selectedStation = null;
      clubsForStation = [];
      selectedClubId = null;
      selectedClubName = null;
      selectedDate = null;
      selectedTimeSlots.clear();
      bookedSlotsForSelected.clear();
    });

    try {
      // Replaced Firestore call with mock service call
      final fetchedStations = await firebaseService.loadStations(_collectionName, zone);
      setState(() {
        stations = fetchedStations;
      });
    } catch (e) {
      debugPrint('Error loading stations: $e');
      setState(() => _errorMessage = 'Error loading stations');
    } finally {
      setState(() => _loadingStations = false);
    }
  }

  // Load clubs for station
  Future<void> _loadClubsForStation(String station) async {
    setState(() {
      _loadingClubs = true;
      clubsForStation = [];
      selectedClubId = null;
      selectedClubName = null;
      selectedDate = null;
      selectedTimeSlots.clear();
      bookedSlotsForSelected.clear();
    });

    try {
      // Replaced Firestore call with mock service call
      final fetchedClubs = await firebaseService.loadClubs(_collectionName, station);
      setState(() {
        clubsForStation = fetchedClubs;
      });
    } catch (e) {
      debugPrint('Error loading clubs for station: $e');
      setState(() => _errorMessage = 'Error loading clubs');
    } finally {
      setState(() => _loadingClubs = false);
    }
  }

  // Fetch booked slots for selected club and date
  Future<void> _fetchBookedSlotsForSelectedClubAndDate() async {
    if (selectedClubId == null || selectedDate == null) {
      setState(() => bookedSlotsForSelected = {});
      return;
    }

    setState(() {
      _loadingBookedSlots = true;
      bookedSlotsForSelected = {};
    });

    try {
      final dateStr = _dateToKey(selectedDate!);
      // Replaced Firestore call with mock service call
      final booked = await firebaseService.fetchBookedSlots(selectedClubId!, dateStr);

      setState(() {
        bookedSlotsForSelected = booked;
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
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  // create booking in firestore; returns bookingId on success, null on failure
  Future<String?> _createBooking() async {
    if (selectedClubId == null || selectedDate == null || selectedTimeSlots.isEmpty) {
      setState(() => _errorMessage = 'Select club, date and at least one time slot');
      return null;
    }

    setState(() {
      _creatingBooking = true;
      _errorMessage = null;
    });

    try {
      final dateKey = _dateToKey(selectedDate!);

      // NOTE: Conflict checking logic removed/simplified as it's complex Firebase logic

      // 3) write new booking and capture id
      final bookingDoc = <String, dynamic>{
        'turfId': selectedClubId,
        'turfName': selectedClubName ?? '',
        'sport': widget.sportName,
        'zone': selectedZone ?? '',
        'station': selectedStation ?? '',
        'date': dateKey,
        'timeSlots': selectedTimeSlots,
        'createdAt': 'MockTimestamp', // Replace FieldValue.serverTimestamp()
      };

      // Replaced Firestore add with mock service call
      final bookingId = await firebaseService.createBooking(bookingDoc);

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

  // navigate to appropriate host screen
  void _navigateToHost(String bookingId, List<String> reservedSlots) {
    if (!mounted) return;

    final sport = widget.sportName.trim().toLowerCase();
    final turfId = selectedClubId!;
    final turfName = selectedClubName ?? '';
    final dateKey = _dateToKey(selectedDate!);

    Widget destination;

    try {
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
      } else if (sport.contains('chess')) {
        destination = Chess(
          bookingId: bookingId,
          turfId: turfId,
          turfName: turfName,
          date: dateKey,
          reservedSlots: reservedSlots,
        );
      } else if (sport.contains('tennis') || sport.contains('table')) {
        destination = TableTennis(
          bookingId: bookingId,
          turfId: turfId,
          turfName: turfName,
          date: dateKey,
          reservedSlots: reservedSlots,
        );
      } else {
        debugPrint("⚠️ Unknown sport: ${widget.sportName}");
        return;
      }
    } catch (e) {
      debugPrint('Error creating host screen: $e');
      destination = Scaffold(
        appBar: AppBar(title: const Text('Host')),
        body: Center(child: Text('Could not open host screen for ${widget.sportName}. Error: $e')),
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

  List<String> _getTimeSlotsForSelectedClub() {
    if (selectedClubId == null) return fallbackTimeSlots;
    final club = clubsForStation.firstWhere((c) => c['id'] == selectedClubId, orElse: () => {});
    final ts = club['timeSlots'];
    if (ts is List && ts.isNotEmpty) {
      return ts.map((e) => e.toString()).toList();
    }
    return fallbackTimeSlots;
  }

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  "Book Club for ${widget.sportName}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Zones dropdown (loaded from sports_clubs collection)
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
                      clubsForStation = [];
                      selectedClubId = null;
                      selectedClubName = null;
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
                        selectedClubId = null;
                        selectedClubName = null;
                        clubsForStation = [];
                        selectedDate = null;
                        selectedTimeSlots.clear();
                        bookedSlotsForSelected.clear();
                      });
                      _loadClubsForStation(v);
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
                              selectedClubId = null;
                              selectedClubName = null;
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

                // Club dropdown (load from clubsForStation)
                if (_loadingClubs)
                  const Center(child: CircularProgressIndicator())
                else if (selectedDate != null && selectedStation != null)
                  _buildDropdown<String>(
                    label: 'Select Club',
                    value: selectedClubId,
                    items: clubsForStation
                        .map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text((c['name'] ?? '') as String, style: const TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      final clubMap = clubsForStation.firstWhere((c) => c['id'] == value, orElse: () => <String, dynamic>{});
                      setState(() {
                        selectedClubId = value;
                        selectedClubName = (clubMap['name'] ?? '').toString();
                        selectedTimeSlots.clear();
                        bookedSlotsForSelected.clear();
                      });
                      // fetch booked slots for new club & date
                      await _fetchBookedSlotsForSelectedClubAndDate();
                    },
                  ),

                const SizedBox(height: 20),

                // Time Slots UI
                if (selectedClubId != null) ...[
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
                    itemCount: _getTimeSlotsForSelectedClub().length,
                    itemBuilder: (context, index) {
                      final slot = _getTimeSlotsForSelectedClub()[index];
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
                      selectedClubId != null &&
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