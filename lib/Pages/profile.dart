//profile.dart
import 'package:flutter/material.dart';
import 'login.dart';
import 'firebase_service.dart';
import 'HostDashboardPage.dart';
import 'events_registered.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // accept nullable userId

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    for (final c in [_fullnameController, _emailController, _phoneController, _ageController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _updateProfile() async {
    // ... (unchanged _updateProfile logic)
    if (widget.userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user id available to update profile")),
        );
      }
      return;
    }

    try {
      await firebaseService.updateProfile(widget.userId!, {
        "fullname": _fullnameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "age": _ageController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }
  }

  Future<void> _logout() async {
    // ... (unchanged _logout logic)
    try {
      await firebaseService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Sign()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  void _navigateToHostDashboard() {
    if (widget.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HostDashboardPage(hostId: widget.userId!),
        ),
      );
    }
  }

  void _navigateToEventsRegistered() { // NEW HANDLER IMPLEMENTED
    if (widget.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventsRegisteredPage(userId: widget.userId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (widget.userId == null) {
      // ... (No user ID message remains the same) ...
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No user signed in', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final uid = widget.userId!;

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
          child: FutureBuilder<Map<String, dynamic>?>(
            future: firebaseService.fetchUserProfile(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text(
                    "User not found or profile data unavailable",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final userData = snapshot.data!;
              // Only update controllers when NOT editing, to avoid overwriting user input
              if (!_isEditing) {
                _fullnameController.text = userData["fullname"] ?? "";
                _emailController.text = userData["email"] ?? "";
                _phoneController.text = userData["phone"] ?? "";
                _ageController.text = userData["age"]?.toString() ?? "";
              }


              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: screenWidth < 500 ? screenWidth * 0.9 : 400,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Color(0xFFB1C900),
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData["fullname"] ?? "N/A",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "@${userData["username"] ?? "N/A"}",
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),


                    const SizedBox(height: 24),

                    // Details Section
                    Container(
                      width: screenWidth < 500 ? screenWidth * 0.9 : 400,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isEditing
                          ? Column(
                        children: [
                          _buildEditableField("Full Name", _fullnameController),
                          _buildEditableField("Email", _emailController),
                          _buildEditableField("Phone", _phoneController),
                          _buildEditableField("Age", _ageController),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF525832),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _updateProfile,
                            child: const Text("Save Changes"),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.email, "Email", userData["email"] ?? "N/A"),
                          const Divider(color: Colors.white24),
                          _buildDetailRow(Icons.phone, "Phone", userData["phone"] ?? "N/A"),
                          const Divider(color: Colors.white24),
                          _buildDetailRow(Icons.cake, "Age", userData["age"]?.toString() ?? "N/A"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- Custom Buttons (Host Dashboard, Events Registered, Logout) ---
                    if (!_isEditing) ...[
                      SizedBox(
                        width: screenWidth < 500 ? screenWidth * 0.9 : 400,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF525832), // Dark Green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _navigateToHostDashboard,
                          child: const Text("Host Dashboard"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: screenWidth < 500 ? screenWidth * 0.9 : 400,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF282A18), // Darker Gray
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _navigateToEventsRegistered, // FIXED NAVIGATION
                          child: const Text("Events Registered"),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Edit/Logout Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF525832),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => setState(() => _isEditing = !_isEditing),
                          child: Text(_isEditing ? "Cancel Edit" : "Edit Profile"),
                        ),
                        const SizedBox(height: 16, width: 16), // Added width 16
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _logout,
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFB1C900)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB1C900)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}