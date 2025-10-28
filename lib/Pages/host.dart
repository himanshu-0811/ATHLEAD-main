import 'package:flutter/material.dart';
import 'turf_booking.dart';
import 'sportsclub_booking.dart'; // adjust path to where you saved it


class Host extends StatelessWidget {
  const Host({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HostRegisterPanel();
  }
}

class _HostRegisterPanel extends StatelessWidget {
  const _HostRegisterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.5, -0.7),
              end: Alignment(0.5, 1.0),
              colors: [
                Color(0xFF525832),
                Color(0xFF282A18),
                Color(0xFF1D1D1D),
              ],
            ),
          ),
          child: const SafeArea(
            child: HostRegisterPanel(),
          ),
        ),
      ),
    );
  }
}

class HostRegisterPanel extends StatelessWidget {
  const HostRegisterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Pick your Sport",
            style: TextStyle(
              color: Colors.white,
              fontSize: (width * 0.06).clamp(20.0, 40.0),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 36),

          // ✅ Fixed 2x2 Grid (fills screen, no scrolling)
          Expanded(
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(), // no scroll
              crossAxisCount: 2, // 2 per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 32,
              childAspectRatio: (width / 2) / ((height - 150) / 2),
              // Ensures 2 rows fit the screen
              children: [
                sportCard('assets/soccer.jpg', 'FOOTBALL', () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TurfBookingPage(sportName: 'Football',)));
                }),

                sportCard('assets/cricket.jpg', 'CRICKET', () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const TurfBookingPage(sportName: 'Cricket',)));
                }),

                sportCard('assets/chess.jpg', 'CHESS', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SportsClubBookingPage(sportName: 'Chess')));
                }),

                sportCard('assets/tt.jpg', 'TENNIS', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SportsClubBookingPage(sportName: 'Table Tennis')));
                }),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sportCard(String asset, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                asset,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.6),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
