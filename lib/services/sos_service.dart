import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class SOSService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> triggerSOS() async {
    User? user = _auth.currentUser;
    if (user == null) return;


    Position pos = await Geolocator.getCurrentPosition();

 
    await _db.collection('emergency_alerts').add({
      'userId': user.uid,
      'userName': user.displayName ?? "Anonymous User",
      'location': GeoPoint(pos.latitude, pos.longitude),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'ACTIVE',
    });
  }
}