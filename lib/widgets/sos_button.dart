import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safestep/pages/alerts.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({super.key});

  Future<void> _makeEmergencyCall() async {
    final Uri telUri = Uri.parse('tel:912'); 
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  Future<void> _logEmergencyToFirebase(BuildContext context) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'userId': user.uid,
        'userName': userData?['name'] ?? user.displayName ?? "User in Distress",
        'userPhoto': userData?['photoUrl'] ?? "", 
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚨 SOS TRIGGERED: BROADCASTING LOCATION..."), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );

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
        height: 75, 
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4), 
              blurRadius: 15, 
              spreadRadius: 1,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Center( // Removed 'const' from here
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 15),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                     "HOLD FOR SOS", 
                    style: TextStyle(
                   color: Colors.white, 
                       fontSize: 20, 
                     fontWeight: FontWeight.w900, // Replaced 'black' with 'w900'
                    letterSpacing: 1.1,
                    ),
                     ),
                  
                  const Text(
                    "DIALS 912 & ALERTS COMMUNITY", 
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}