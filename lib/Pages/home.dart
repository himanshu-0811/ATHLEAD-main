import 'package:flutter/material.dart';
import 'profile.dart';
import 'host.dart';
import 'registration.dart';

class AndroidCompact2 extends StatelessWidget {
  final String? userId;
  const AndroidCompact2({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          width: width,
          height: height,
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
          child: Column(
            children: [
              // Top Logo and Avatar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.01,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(userId: userId),
                          ),
                        );
                      },
                      child: Container(
                        width: width * 0.13,
                        height: width * 0.13,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/profile.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Banner Image
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: Container(
                  width: double.infinity,
                  height: height * 0.22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/football.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.015),

              Text(
                'Pick your sport',
                style: TextStyle(
                  color: const Color(0xFFEBECE6),
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),

              SizedBox(height: height * 0.02),


              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: width * 0.05,
                    mainAxisSpacing: height * 0.025,
                    childAspectRatio: 0.8,
                    children: [
                      sportCard(context, 'assets/soccer.jpg', 'FOOTBALL', width),
                      sportCard(context, 'assets/chess.jpg', 'CHESS', width),
                      sportCard(context, 'assets/cricket.jpg', 'CRICKET', width),
                      sportCard(context, 'assets/tt.jpg', 'TENNIS', width),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1D1D1D),
        padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: navButton('Join', context)),
            const SizedBox(width: 10),
            Expanded(child: navButton('Home', context)),
            const SizedBox(width: 10),
            Expanded(child: navButton('Host', context)),
          ],
        ),
      ),
    );
  }

  Widget sportCard(BuildContext context, String asset, String label, double width) {
    return GestureDetector(
      onTap: () {
        // Navigate to Events and pre-select the tapped sport
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Events(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFFEBECE6),
                fontSize: width * 0.05,
                fontFamily: 'Impact',
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget navButton(String title, BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (title == 'Host') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Host()),
          );
        } else if (title == 'Home') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AndroidCompact2(userId: userId),
            ),
          );
        } else if (title == 'Join') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Events(),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3A3A3A),
        foregroundColor: const Color(0xFFEBECE6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(title),
    );
  }
}
