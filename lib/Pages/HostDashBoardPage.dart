// host_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// This package dependency must be installed via pubspec.yaml
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'firebase_service.dart';

// Theme colors from the main app
const Color kPrimaryColor = Color(0xFF525832);
const Color kAccentColor = Color(0xFFB1C900);
const Color kDarkBackground = Color(0xFF1D1D1D);

class HostDashboardPage extends StatelessWidget {
  final String hostId;
  const HostDashboardPage({super.key, required this.hostId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Dashboard', style: TextStyle(color: Colors.white)),
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
          child: HostEventsList(hostId: hostId),
        ),
      ),
    );
  }
}

class HostEventsList extends StatelessWidget {
  final String hostId;
  HostEventsList({required this.hostId});

  final List<String> hostCollections = [
    'crickethost',
    'footballhost',
    'chesshost',
    'tabletennishost',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: hostCollections.map((collection) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collection)
              .where('hostUserId', isEqualTo: hostId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kAccentColor));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading $collection: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return EventCardSummary(
                  eventCollection: collection,
                  eventDocId: doc.id,
                  eventData: data,
                );
              }).toList(),
            );
          },
        );
      }).toList(),
    );
  }
}

class EventCardSummary extends StatelessWidget {
  final String eventCollection;
  final String eventDocId;
  final Map<String, dynamic> eventData;

  const EventCardSummary({
    required this.eventCollection,
    required this.eventDocId,
    required this.eventData,
  });

  @override
  Widget build(BuildContext context) {
    final eventName = eventData['eventName'] ?? 'Untitled Event';
    final totalSlots = eventData['teamSlots'] ?? eventData['slots'] ?? 0;
    final registeredCount = eventData['registeredTeamsCount'] ?? 0;
    final slotsLeft = (totalSlots - registeredCount) < 0 ? 0 : (totalSlots - registeredCount);
    final isSoloGame = eventCollection == 'chesshost' || eventCollection == 'tabletennishost';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTileCard(  // <-- This widget now works
        initialPadding: const EdgeInsets.all(0),
        title: Text(eventName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Date: ${eventData['date']} | Sport: ${eventData['sport'] ?? 'N/A'}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$registeredCount / $totalSlots', style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
            Text('Slots Left: $slotsLeft', style: TextStyle(color: slotsLeft > 0 ? Colors.greenAccent : Colors.red, fontSize: 12)),
          ],
        ),
        baseColor: const Color(0xFF282A18).withOpacity(0.9),
        expandedColor: const Color(0xFF282A18),
        duration: const Duration(milliseconds: 300),
        children: [
          Divider(thickness: 1.0, height: 1.0, color: Colors.white10.withOpacity(0.2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: RegistrationDetailsView(
              registrationCollection: '${eventCollection}_registration',
              hostDocId: eventDocId,
              isSoloGame: isSoloGame,
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationDetailsView extends StatelessWidget {
  final String registrationCollection;
  final String hostDocId;
  final bool isSoloGame;

  RegistrationDetailsView({
    required this.registrationCollection,
    required this.hostDocId,
    required this.isSoloGame,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(registrationCollection)
          .where('hostDocId', isEqualTo: hostDocId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kAccentColor));
        }
        if (snapshot.hasError) {
          return Text('Error loading registrations: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No registrations yet.', style: TextStyle(color: Colors.white70));
        }

        final registrations = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registered Participants:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...registrations.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final teamName = data['teamName'] as String? ?? 'Solo Player';
              final players = data['players'] as List<dynamic>? ?? [];

              if (isSoloGame) {
                // SOLO GAME: Display details directly
                final player = players.isNotEmpty ? players.first : {};
                return PlayerDetailDisplay(
                  role: 'Solo Player',
                  fullName: player['fullName'] ?? 'N/A',
                  phone: player['phone'] ?? 'N/A',
                  email: player['email'] ?? 'N/A',
                  age: player['age'] ?? 'N/A',
                );
              } else {
                // TEAM GAME: Display team card with expandable player details
                return TeamDetailCard(
                  teamName: teamName,
                  players: players.cast<Map<String, dynamic>>(),
                );
              }
            }).toList(),
          ],
        );
      },
    );
  }
}

// Widget to display individual player details (used for solo games)
class PlayerDetailDisplay extends StatelessWidget {
  final String role;
  final String fullName;
  final String phone;
  final String email;
  final String age;

  const PlayerDetailDisplay({
    required this.role,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kDarkBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$role: $fullName',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text('Phone: $phone', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('Email: $email', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('Age: $age', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// Widget for Team Game view (expandable)
class TeamDetailCard extends StatelessWidget {
  final String teamName;
  final List<Map<String, dynamic>> players;

  const TeamDetailCard({
    required this.teamName,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final captain = players.firstWhere((p) => p['role'] == 'Captain', orElse: () => players.first);
    final totalPlayers = players.length;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ExpansionTileCard( // <-- This widget now works
        title: Text(teamName, style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
        subtitle: Text('Captain: ${captain['fullName'] ?? 'N/A'} ($totalPlayers players)', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        baseColor: kDarkBackground,
        expandedColor: kDarkBackground.withOpacity(0.9),
        duration: const Duration(milliseconds: 300),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: players.map((player) {
                return PlayerDetailDisplay(
                  role: player['role'] as String? ?? 'Player',
                  fullName: player['fullName'] ?? 'N/A',
                  phone: player['phone'] ?? 'N/A',
                  email: player['email'] ?? 'N/A',
                  age: player['age'] ?? 'N/A',
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}