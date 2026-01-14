import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("COMMAND CENTER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatSummary(),
              const SizedBox(height: 24),
              const Text("LIVE INCIDENT LOG", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildCombinedLogs(),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Cards: Showing total counts
  Widget _buildStatSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('emergency_alerts').snapshots(),
      builder: (context, sosSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reports').snapshots(),
          builder: (context, reportSnapshot) {
            int sosCount = sosSnapshot.data?.docs.where((d) => d['status'] == 'ACTIVE').length ?? 0;
            int reportCount = reportSnapshot.data?.docs.length ?? 0;

            return Row(
              children: [
                _statCard("ACTIVE SOS", sosCount.toString(), Colors.redAccent),
                const SizedBox(width: 12),
                _statCard("TOTAL REPORTS", reportCount.toString(), Colors.blueAccent),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// 2. The Log: Mixed list of SOS and Hazards
  Widget _buildCombinedLogs() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_alerts')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            DateTime? time = (data['timestamp'] as Timestamp?)?.toDate();
            
            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: data['status'] == 'ACTIVE' ? Colors.red : Colors.green,
                  child: Icon(data['status'] == 'ACTIVE' ? Icons.warning : Icons.check, color: Colors.white, size: 16),
                ),
                title: Text(data['userName'] ?? "Unknown User", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("Status: ${data['status']}", style: const TextStyle(color: Colors.white60)),
                trailing: Text(
                  time != null ? DateFormat('HH:mm').format(time) : "--:--",
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
            );
          },
        );
      },
    );
  }
}