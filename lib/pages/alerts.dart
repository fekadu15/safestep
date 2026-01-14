import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:safestep/pages/home.dart';
import 'package:safestep/pages/profile.dart';
import 'package:safestep/pages/report.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final int _currentIndex = 1;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "Community Alerts",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildCategoryChip(),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // UPDATE: Removed .orderBy here to prevent the "disappearing" bug
                // We will sort manually in the builder instead.
                stream: FirebaseFirestore.instance
                    .collection('emergency_alerts')
                    .where('status', whereIn: ['ACTIVE', 'RESPONDING'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildNoAlertsPlaceholder();
                  }

                  // UPDATE: Manual sort to handle the "null timestamp" during upload
                  final docs = snapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                    final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                    if (aTime == null) return -1; // Newest (null) at top
                    if (bTime == null) return 1;
                    return bTime.compareTo(aTime);
                  });

                  return ListView.builder(
                    itemCount: docs.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildLiveAlertCard(data, doc.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, color: Colors.redAccent, size: 18),
          SizedBox(width: 8),
          Text(
            "Live SOS Alerts",
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAlertCard(Map<String, dynamic> data, String docId) {
    // UPDATE: Use current time as fallback if Firestore hasn't set the server time yet
    DateTime time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    String formattedTime = DateFormat('jm').format(time);
    
    String status = data['status'] ?? "ACTIVE";
    bool isResponding = status == "RESPONDING";
    bool isMyAlert = data['userId'] == currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isMyAlert ? const Color(0xFF1E1B4B) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMyAlert ? Colors.blueAccent : (isResponding ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.2)),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isMyAlert ? Icons.person_pin_circle : (isResponding ? Icons.verified_user : Icons.warning_amber_rounded),
                    color: isMyAlert ? Colors.blueAccent : (isResponding ? Colors.greenAccent : Colors.redAccent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMyAlert ? "YOUR SIGNAL" : (isResponding ? "HELP ON THE WAY" : "DISTRESS SIGNAL"),
                    style: TextStyle(
                      color: isMyAlert ? Colors.blueAccent : (isResponding ? Colors.greenAccent : Colors.redAccent),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(formattedTime, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isResponding 
              ? "${data['userName']} is being assisted by ${data['responderName'] ?? 'a rescuer'}."
              : "${data['userName'] ?? 'A user'} is in distress and requested help nearby.",
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              if (isMyAlert)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('emergency_alerts').doc(docId).update({'status': 'RESOLVED'});
                    },
                    child: const Text("I AM SAFE NOW", style: TextStyle(color: Colors.white)),
                  ),
                )
              else 
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map, color: Colors.white, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // Navigate to map and show the location
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false
                      );
                    },
                    label: const Text("VIEW ON MAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_moon_outlined, size: 80, color: Colors.blueAccent.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            "The community is currently safe.",
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white38,
      currentIndex: _currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.add_location_alt_outlined), label: "Report"),
        BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: "Profile"),
      ],
      onTap: (index) {
        if (index == _currentIndex) return;
        Widget nextPage;
        switch (index) {
          case 0: nextPage = const HomePage(); break;
          case 2: nextPage = const ReportPage(); break;
          case 3: nextPage = const ProfilePage(); break;
          default: nextPage = const HomePage();
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextPage));
      },
    );
  }
}