import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safestep/pages/alerts.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({super.key});

  /// 1. Triggers the physical phone call
  Future<void> _makeEmergencyCall() async {
    // Using 911/991/912 depending on your region
    final Uri telUri = Uri.parse('tel:912'); 
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  /// 2. Logs the emergency in Firebase for the community/SafeCircle
  Future<void> _logEmergencyToFirebase(BuildContext context) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      
      // Get precise location at the moment of the SOS
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'userId': user?.uid,
        'userName': user?.displayName ?? "User in Distress",
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'ACTIVE',
      });
    } catch (e) {
      debugPrint("Failed to log SOS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        // Provide haptic/visual feedback immediately
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("EMERGENCY TRIGGERED: BROADCASTING LOCATION..."), 
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        // Run both actions
        await Future.wait([
          _logEmergencyToFirebase(context),
          _makeEmergencyCall(),
        ]);
      },
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const AlertsPage())
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4), 
              blurRadius: 20, 
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emergency_share, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("HOLD FOR SOS", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("DIALS EMERGENCY & ALERTS CIRCLE", 
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}