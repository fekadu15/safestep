import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final String routeName;
  final String duration;

  const RouteCard({
    super.key, 
    required this.routeName, 
    required this.duration
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2), 
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: const Text("RECOMMENDED", 
                    style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(routeName, 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white54, size: 14),
                    Text(" $duration  •  ", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const Icon(Icons.wb_sunny_outlined, color: Colors.greenAccent, size: 14),
                    const Text(" Well-lit", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 25, 
            backgroundColor: Colors.blueAccent, 
            child: Icon(Icons.navigation, color: Colors.white)
          ),
        ],
      ),
    );
  }
}