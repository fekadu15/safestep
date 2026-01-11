import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ───────── PROFILE HEADER ─────────
            _profileHeader(),
            const SizedBox(height: 30),

            // ───────── QUICK STATS ─────────
            _statsRow(),
            const SizedBox(height: 30),

            // ───────── SETTINGS ─────────
            _sectionTitle("Account"),
            _profileTile(Icons.person, "Edit Profile"),
            _profileTile(Icons.security, "Privacy & Security"),
            _profileTile(Icons.location_on, "Trusted Locations"),

            const SizedBox(height: 25),

            _sectionTitle("Safety"),
            _profileTile(Icons.people, "Trusted Contacts"),
            _profileTile(Icons.notifications, "Alert Preferences"),
            _profileTile(Icons.shield, "Safety Settings"),

            const SizedBox(height: 25),

            _sectionTitle("Other"),
            _profileTile(Icons.help_outline, "Help & Support"),
            _profileTile(Icons.info_outline, "About SafeStep"),

            const SizedBox(height: 30),

            // ───────── LOGOUT ─────────
            _logoutButton(),
          ],
        ),
      ),
    );
  }

  // ───────── PROFILE HEADER ─────────
  Widget _profileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 45,
          backgroundColor: Color(0xFF2563EB),
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          "Alex Johnson",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "alex@email.com",
          style: TextStyle(color: Colors.white54),
        ),
      ],
    );
  }

  // ───────── STATS ─────────
  Widget _statsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem("Trips", "24"),
        _statItem("SOS Used", "3"),
        _statItem("Safe Routes", "18"),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    );
  }

  // ───────── SECTION TITLE ─────────
  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ───────── TILE ─────────
  Widget _profileTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2563EB).withOpacity(0.15),
          child: Icon(icon, color: const Color(0xFF2563EB)),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          debugPrint("$title tapped");
        },
      ),
    );
  }

  // ───────── LOGOUT ─────────
  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          debugPrint("Logout");
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Log Out",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
