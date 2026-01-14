import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For GestureRecognizers
import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? selectedType;
  final TextEditingController detailsController = TextEditingController();
  LatLng _reportPosition = const LatLng(9.03, 38.74); 
  bool _isLoadingLoc = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initReportLocation();
  }

  Future<void> _initReportLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _reportPosition = LatLng(pos.latitude, pos.longitude);
          _isLoadingLoc = false;
        });
        _mapController.move(_reportPosition, 16);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLoc = false);
    }
  }

  Future<void> _submitReport() async {
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select incident type")));
      return;
    }

    // Show loading overlay
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
    );

    try {
      // SYNCED WITH SRA SCHEMA: uses 'reportedBy' and 'location' as GeoPoint
      await FirebaseFirestore.instance.collection('reports').add({
        'type': selectedType,
        'details': detailsController.text.trim(),
        'location': GeoPoint(_reportPosition.latitude, _reportPosition.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'reportedBy': FirebaseAuth.instance.currentUser?.uid, // Matches security rules
        'status': 'ACTIVE',
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Back to Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Report shared with the community!"))
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Community Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoadingLoc 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pin Incident Location", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                
                // --- INTERACTIVE PINNING MAP ---
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _reportPosition,
                            initialZoom: 16,
                            onPositionChanged: (pos, _) => _reportPosition = pos.center!,
                            // Prevents the page from scrolling while you're moving the map
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              tileBuilder: (context, widget, tile) => ColorFiltered(
                                colorFilter: const ColorFilter.matrix([0.21, 0.71, 0.07, 0, -160, 0.21, 0.71, 0.07, 0, -160, 0.21, 0.71, 0.07, 0, -160, 0, 0, 0, 1, 0]),
                                child: widget,
                              ),
                            ),
                          ],
                        ),
                        // FIXED CENTER PIN
                        const IgnorePointer(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 35),
                              child: Icon(Icons.location_on, color: Colors.redAccent, size: 45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                const Text("Select Incident Category", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _typeCard("Poor lighting", Icons.wb_incandescent_outlined),
                    _typeCard("Harassment", Icons.warning_amber),
                    _typeCard("Suspicious", Icons.visibility),
                    _typeCard("Accident", Icons.car_crash),
                  ],
                ),
                
                const SizedBox(height: 25),
                const Text("Additional Details", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Describe the hazard (e.g. 'Street lights out for 2 blocks')",
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: _submitReport,
                    child: const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _typeCard(String label, IconData icon) {
    bool sel = selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => selectedType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: sel ? Colors.blueAccent : const Color(0xFF1E293B), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: sel ? Colors.white24 : Colors.transparent)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}