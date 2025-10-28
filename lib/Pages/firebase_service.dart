// firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer';

final firebaseService = FirebaseService();

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -----------------------------------------------------------------------
  // 1. AUTHENTICATION (Login, Register, Logout)
  // -----------------------------------------------------------------------

  /// Simulates user login using Firebase Auth, checking for email or username.
  /// Throws [FirebaseAuthException] or generic [Exception] on failure.
  Future<String> login(String usernameOrEmail, String password) async {
    String email = usernameOrEmail.trim();

    // 1. Try to sign in directly with email.
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        // Assume the user entered a username. Query Firestore for the corresponding email.
        final usernameSnapshot = await _firestore
            .collection("users")
            .where("username", isEqualTo: usernameOrEmail.trim())
            .limit(1)
            .get();

        if (usernameSnapshot.docs.isNotEmpty) {
          final userData = usernameSnapshot.docs.first.data();
          final storedEmail = userData['email'] as String?;

          if (storedEmail != null) {
            // 2. If a username is found, attempt sign-in with the stored email and provided password.
            try {
              final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                email: storedEmail,
                password: password,
              );
              return userCredential.user!.uid;
            } on FirebaseAuthException {
              // Sign-in failed with the fetched email (likely wrong password)
              rethrow;
            }
          }
        }
      }
      // Re-throw the original error if unhandled.
      rethrow;
    }
  }

  /// Creates a new user account with Firebase Auth and stores profile data in Firestore.
  Future<String> register(Map<String, String> userData) async {
    final email = userData['email']!;
    final password = userData['password']!;

    // 1. Create user account with Firebase Authentication
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final userId = userCredential.user!.uid;

    // 2. Store additional user data in Firestore
    await _firestore.collection("users").doc(userId).set({
      "fullname": userData["fullname"],
      "username": userData["username"],
      "age": userData["age"],
      "phone": userData["phone"],
      "email": email,
      "eventsHosted": 0,
    });

    return userId;
  }

  /// Signs the current user out.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // -----------------------------------------------------------------------
  // 2. USER PROFILE (Fetch and Update)
  // -----------------------------------------------------------------------

  /// Fetches user data from Firestore using the UID.
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final doc = await _firestore.collection("users").doc(userId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  /// Updates user data in Firestore.
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection("users").doc(userId).update(data);
  }

  // -----------------------------------------------------------------------
  // 3. BOOKING/VENUE DATA (Zones, Stations, Clubs)
  // -----------------------------------------------------------------------

  /// Loads unique zones from a specified collection.
  Future<List<String>> loadZones(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    final Set<String> zoneSet = {};
    for (final doc in snapshot.docs) {
      final z = (doc.data()['zone'] ?? '').toString();
      if (z.isNotEmpty) zoneSet.add(z);
    }
    return zoneSet.toList()..sort();
  }

  /// Loads unique stations for a chosen zone.
  Future<List<String>> loadStations(String collection, String zone) async {
    final q = await _firestore.collection(collection).where('zone', isEqualTo: zone).get();
    final Set<String> stationSet = {};
    for (final doc in q.docs) {
      final st = (doc.data()['station'] ?? '').toString();
      if (st.isNotEmpty) stationSet.add(st);
    }
    return stationSet.toList()..sort();
  }

  /// Loads clubs/turfs (documents) for a chosen station.
  Future<List<Map<String, dynamic>>> loadClubs(String collection, String station) async {
    final q = await _firestore.collection(collection).where('station', isEqualTo: station).get();
    final List<Map<String, dynamic>> list = [];
    for (final doc in q.docs) {
      final data = doc.data();
      List<String> timeSlots = (data['timeSlots'] is List)
          ? List<String>.from(data['timeSlots'])
          : [];

      list.add({
        'id': doc.id,
        'name': (data['name'] ?? data['turfName'] ?? '').toString(),
        'capacity': data['capacity'] ?? 1,
        'contact': data['contact'] ?? '',
        'address': data['address'] ?? '',
        'zone': data['zone'] ?? '',
        'station': data['station'] ?? '',
        'timeSlots': timeSlots,
      });
    }
    list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return list;
  }

  // -----------------------------------------------------------------------
  // 4. BOOKING AND EVENT HOSTING
  // -----------------------------------------------------------------------

  /// Creates a final, confirmed booking record in the 'bookings' collection.
  /// This ID is essential for linking the host event back to the venue reservation.
  Future<String> createBooking(Map<String, dynamic> bookingDoc) async {
    final docWithTimestamp = {
      ...bookingDoc,
      'createdAt': FieldValue.serverTimestamp(),
    };
    final ref = await _firestore.collection('bookings').add(docWithTimestamp);
    return ref.id;
  }

  /// Fetches booked slots for a specific turf/club and date. Used for availability check.
  Future<Set<String>> fetchBookedSlots(String turfId, String dateKey) async {
    final q = await _firestore
        .collection('bookings')
        .where('turfId', isEqualTo: turfId)
        .where('date', isEqualTo: dateKey)
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
    return booked;
  }

  /// Fetches booking details (station, address, etc.) for a specific booking ID.
  Future<Map<String, dynamic>?> fetchBookingDetails(String bookingId) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    return doc.data();
  }

  /**
   * Creates an event document in the specified host collection.
   * This includes a check to prevent double-hosting using the same booking ID.
   * Host's UID is included in the data passed to this function.
   */
  Future<void> createHostEvent(String collectionName, Map<String, dynamic> data) async {
    final bookingId = data['bookingId'] as String?;
    final reservedSlots = data['reservedSlots'] as List<String>?;
    final date = data['date'] as String?;

    if (bookingId == null || reservedSlots == null || reservedSlots.isEmpty || date == null || date.isEmpty) {
      throw Exception("Booking details (ID, date, slots) are required to host an event.");
    }

    // --- CONFLICT CHECK LOGIC: Prevent double-hosting the same booked slot ---

    final existingEvents = await _firestore
        .collection(collectionName)
        .where('bookingId', isEqualTo: bookingId)
        .where('date', isEqualTo: date)
        .get();

    if (existingEvents.docs.isNotEmpty) {
      // Check if any existing document is using the exact same set of reserved slots
      final existingReserved = existingEvents.docs.first.data()['reservedSlots'] as List<dynamic>?;
      if (existingReserved != null &&
          existingReserved.toSet().intersection(reservedSlots.toSet()).isNotEmpty) {
        throw Exception("Conflict: This booking ID is already in use for one or more of these time slots on $date.");
      }
    }

    // --- WRITE OPERATION ---

    final docWithTimestamp = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection(collectionName).add(docWithTimestamp);
  }

  /// Registers a player/team for an event, linking it to the specific host and event.
  /// Schema: Saves registration details to {sport}host_registration and increments count on host document.
  Future<void> registerForEvent(String collectionName, Map<String, dynamic> data) async {
    final userId = _auth.currentUser?.uid; // ID of the user joining the event

    if (userId == null) {
      throw Exception("User must be logged in to register for an event.");
    }

    final eventDocId = data['hostDocId'] as String?;
    if (eventDocId == null || eventDocId.isEmpty) {
      throw Exception("Event ID is missing from registration data.");
    }

    // Determine the host collection name (e.g., 'crickethost')
    final baseCollection = collectionName.replaceAll('_registration', '');

    // 1. Get the original host document to find the Uid of the host user
    String hostUserId = 'UNKNOWN_HOST';
    try {
      final hostDoc = await _firestore.collection(baseCollection).doc(eventDocId).get();
      if (hostDoc.exists) {
        // Retrieve the stored hostUserId from the event document
        hostUserId = hostDoc.data()?['hostUserId'] as String? ?? 'UNKNOWN_HOST';
      }
    } catch (e) {
      log('Error fetching host ID for registration: $e');
    }

    // 2. Prepare the registration document
    final docWithTimestamp = {
      ...data,
      'registeredByUserId': userId,
      'hostUserId': hostUserId,     // Crucial for the Host Dashboard filter
      'createdAt': FieldValue.serverTimestamp(),
    };

    // 3. Add to the new, specific registration collection (e.g., 'crickethost_registration')
    await _firestore.collection(collectionName).add(docWithTimestamp);

    // 4. Increment the registered count on the host document (for display)
    // This is an atomic operation to prevent concurrency issues on the counter
    await _firestore.collection(baseCollection).doc(eventDocId).update({
      'registeredTeamsCount': FieldValue.increment(1),
    }).catchError((error) {
      // Log error if increment fails (e.g., if the host document was deleted), but let registration succeed.
      log("Warning: Failed to increment registeredTeamsCount: $error");
    });
  }
}