// events_registered.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart'; // For theme colors
import 'package:expansion_tile_card/expansion_tile_card.dart'; // For expandable details

// Theme colors from the main app
const Color kPrimaryColor = Color(0xFF525832);
const Color kAccentColor = Color(0xFFB1C900);
const Color kDarkBackground = Color(0xFF1D1D1D);

class EventsRegisteredPage extends StatelessWidget {
  final String userId;
  const EventsRegisteredPage({super.key, required this.userId});

  // Collections we need to query for user registrations
  final List<String> registrationCollections = const [
    'crickethost_registration',
    'footballhost_registration',
    'chesshost_registration',
    'tabletennishost_registration',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Registered', style: TextStyle(color: Colors.white)),
        backgroundColor: kDarkBackground,
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, -0.7),
            end: Alignment(0.50, 1.00),
            colors: [
              kPrimaryColor,
              Color(0xFF282A18),
              kDarkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: RegistrationList(userId: userId, collections: registrationCollections),
        ),
      ),
    );
  }
}

class RegistrationList extends StatelessWidget {
  final String userId;
  final List<String> collections;

  const RegistrationList({required this.userId, required this.collections});

  @override
  Widget build(BuildContext context) {
    // List to hold all future registration results
    final List<Future<QuerySnapshot>> futures = collections.map((collection) {
      return FirebaseFirestore.instance
          .collection(collection)
          .where('registeredByUserId', isEqualTo: userId)
          .get();
    }).toList();

    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait(futures),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kAccentColor));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading data: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No events found.', style: TextStyle(color: Colors.white70)));
        }

        // Flatten all query snapshots into a single list of documents
        final allDocs = snapshot.data!.expand((query) => query.docs).toList();

        if (allDocs.isEmpty) {
          return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('You have not registered for any events yet.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: allDocs.length,
          itemBuilder: (context, index) {
            final doc = allDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final eventTitle = data['eventTitle'] ?? 'Unnamed Event';
            final players = data['players'] as List<dynamic>? ?? [];
            final teamName = data['teamName'] ?? 'Solo Entry';

            // Determine the base collection from the registration collection name
            final regCollectionName = doc.reference.parent.id;
            final baseCollection = regCollectionName.replaceAll('_registration', '');

            // Fetch the host event details for date/location
            return HostEventDetail(
              eventTitle: eventTitle,
              teamName: teamName,
              players: players.cast<Map<String, dynamic>>(),
              hostDocId: data['hostDocId'] ?? '',
              baseCollection: baseCollection,
            );
          },
        );
      },
    );
  }
}

class HostEventDetail extends StatelessWidget {
  final String eventTitle;
  final String teamName;
  final List<Map<String, dynamic>> players;
  final String hostDocId;
  final String baseCollection;

  const HostEventDetail({
    required this.eventTitle,
    required this.teamName,
    required this.players,
    required this.hostDocId,
    required this.baseCollection,
  });

  // Helper to format player details for team games
  String _getPlayersSummary() {
    if (players.length == 1) return 'Solo Player';
    final captainName = players.firstWhere(
            (p) => p['role'] == 'Captain',
        orElse: () => players.first)['fullName'] ?? 'N/A';
    return 'Team Captain: $captainName (${players.length} members)';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // Fetch the main event document for date and location
      future: FirebaseFirestore.instance.collection(baseCollection).doc(hostDocId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(color: kAccentColor);
        }

        String date = 'Date Unavailable';
        String location = 'Location Unavailable';
        String time = 'Time Unavailable';

        if (snapshot.hasData && snapshot.data!.exists) {
          final hostData = snapshot.data!.data() as Map<String, dynamic>;
          date = hostData['date'] ?? date;
          location = hostData['location'] ?? hostData['turfName'] ?? location;
          time = hostData['timeSlot'] ?? hostData['time'] ?? time;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ExpansionTileCard(
            title: Text(eventTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('$baseCollection | $date at $time', style: const TextStyle(color: Colors.white70)),
            baseColor: const Color(0xFF282A18).withOpacity(0.9),
            expandedColor: const Color(0xFF282A18),
            children: [
              Divider(thickness: 1.0, height: 1.0, color: Colors.white10.withOpacity(0.2)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Venue: $location', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Text(
                      players.length > 1 ? 'Team Name: $teamName' : 'Registration Details:',
                      style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Display Player/Team details (Collapsible for teams, direct for solo)
                    ...players.map((player) {
                      return PlayerDisplayTile(player: player);
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlayerDisplayTile extends StatelessWidget {
  final Map<String, dynamic> player;

  const PlayerDisplayTile({required this.player});

  @override
  Widget build(BuildContext context) {
    final role = player['role'] as String? ?? 'Player';
    final fullName = player['fullName'] as String? ?? 'N/A';
    final phone = player['phone'] as String? ?? 'N/A';
    final email = player['email'] as String? ?? 'N/A';
    final age = player['age'] as String? ?? 'N/A';

    // Use an ExpansionTileCard for team players, or just a simple container for solo/detail visibility
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kDarkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: role == 'Captain' ? kAccentColor : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$role: $fullName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Phone: $phone', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text('Email: $email', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text('Age: $age', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}