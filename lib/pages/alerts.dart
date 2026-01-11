import 'package:flutter/material.dart';
import 'package:safestep/pages/home.dart';
import 'package:safestep/pages/profile.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Alerts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // later: mark all as read
            },
            child: const Text(
              "Mark all read",
              style: TextStyle(color: Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryChip(),
            const SizedBox(height: 20),
            _buildAlertCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // 🔴 Critical Chip
  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text("Critical", style: TextStyle(color: Colors.white)),
    );
  }

  // 🚨 Alert Card
  Widget _buildAlertCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Unsafe Zone detected",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                "1:05",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "High crime activity reported around your current location",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // later: open safety map
              },
              child: const Text(
                "View safety map",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔻 Bottom Navigation
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      backgroundColor: const Color(0xFF111827),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: "Alert",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
      onTap: (index) {
        // later: navigation logic
      },
    );
  }
}
