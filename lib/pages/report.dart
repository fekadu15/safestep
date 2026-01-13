import 'package:flutter/material.dart';
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
      setState(() {
        _reportPosition = LatLng(pos.latitude, pos.longitude);
        _isLoadingLoc = false;
      });
      _mapController.move(_reportPosition, 16);
    } catch (_) {
      setState(() => _isLoadingLoc = false);
    }
  }

  Future<void> _submitReport() async {
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select incident type")));
      return;
    }

    // Show loading
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': selectedType,
        'details': detailsController.text,
        'location': GeoPoint(_reportPosition.latitude, _reportPosition.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'status': 'ACTIVE',
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Back to Home
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Report shared!")));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Community Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pin Location", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _reportPosition,
                    initialZoom: 16,
                    onPositionChanged: (pos, _) => _reportPosition = pos.center, // Drag map to pin
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileBuilder: (context, widget, tile) => ColorFiltered(
                        colorFilter: const ColorFilter.matrix([0.21, 0.71, 0.07, 0, -160, 0.21, 0.71, 0.07, 0, -160, 0.21, 0.71, 0.07, 0, -160, 0, 0, 0, 1, 0]),
                        child: widget,
                      ),
                    ),
                    const Center(child: Icon(Icons.location_on, color: Colors.redAccent, size: 40)), // Center pin
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text("What did you see?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
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
            TextField(
              controller: detailsController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Optional details...",
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: StadiumBorder()),
                onPressed: _submitReport,
                child: const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      child: Container(
        decoration: BoxDecoration(color: sel ? Colors.blueAccent : const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    );
  }
}