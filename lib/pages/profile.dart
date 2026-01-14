import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safestep/pages/home.dart';
import 'package:safestep/services/auth_service.dart';
import 'package:safestep/pages/admin_dashboard.dart'; // Make sure this import is correct

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  // --- REPLACE THIS WITH YOUR ACTUAL UID FROM FIREBASE AUTH ---
  final String _adminUid = "mVfRKSbuEHPeGwPzyvdhLkRbiq33"; 

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        File file = File(pickedFile.path);
        Reference ref = FirebaseStorage.instance.ref().child('profile_pics').child('${user!.uid}.jpg');
        
        await ref.putFile(file);
        String url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'photoUrl': url,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error: $e");
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _editProfile(Map<String, dynamic> data) {
    final name = TextEditingController(text: data['fullName'] ?? user?.displayName ?? "");
    final phone = TextEditingController(text: data['phoneNumber'] ?? "");
    final emg = TextEditingController(text: data['emergencyContact'] ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Full Name", labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Phone", labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: emg, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Emergency Contact", labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
                  'fullName': name.text,
                  'phoneNumber': phone.text,
                  'emergencyContact': emg.text,
                }, SetOptions(merge: true));
                Navigator.pop(context);
              },
              child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())),
        ),
        title: const Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                // --- Avatar Section ---
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF2563EB),
                      backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                      child: data['photoUrl'] == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _uploadImage,
                        child: CircleAvatar(
                          radius: 18, backgroundColor: Colors.white,
                          child: _isUploading ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text(data['fullName'] ?? user?.displayName ?? "User", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(user?.email ?? "", style: const TextStyle(color: Colors.white54)),
                
                const SizedBox(height: 30),

                // --- Admin Section (Hidden from normal users) ---
                if (user?.uid == _adminUid) ...[
                  _adminCard(),
                  const SizedBox(height: 20),
                ],

                // --- Info Cards ---
                _infoCard(Icons.phone, "Phone", data['phoneNumber'] ?? "Not added"),
                _infoCard(Icons.contact_emergency, "Emergency", data['emergencyContact'] ?? "Not added"),
                
                const SizedBox(height: 30),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1), 
                    minimumSize: const Size(double.infinity, 55), 
                    side: const BorderSide(color: Colors.blueAccent)
                  ),
                  onPressed: () => _editProfile(data),
                  child: const Text("EDIT PROFILE", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 15),
                
                TextButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Admin Dashboard Entry Widget
  Widget _adminCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.orange.shade900]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
        title: const Text("ADMIN COMMAND CENTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text("Monitor community alerts & SOS", style: TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const AdminDashboard())
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ])
        ],
      ),
    );
  }
}