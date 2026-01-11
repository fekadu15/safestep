import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Updated
import 'package:latlong2/latlong.dart'; // Added for coordinates

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? selectedType;
  final TextEditingController detailsController = TextEditingController();
  
  // Updated to LatLng from latlong2 package
  static const LatLng _mapCenter = LatLng(40.7128, -74.0060);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121826),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          color: Colors.white54,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Report Incident",
          style: TextStyle(color: Colors.white54),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "SOS",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAP PREVIEW (Updated to OpenStreetMap)
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 14,
                    interactionOptions: InteractionOptions(flags: InteractiveFlag.none), // Keeps preview static
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.safestep.app',
                    ),
                    const MarkerLayer(
                      markers: [
                        Marker(
                          point: _mapCenter,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on, color: Colors.red, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TITLE
            const Text(
              "what happened ?",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12), // Slightly increased for breathing room

            // INCIDENT TYPES
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _incidentCard("Poor lighting", Icons.wb_sunny_outlined),
                _incidentCard("Harassment", Icons.block),
                _incidentCard("Suspicious", Icons.remove_red_eye_outlined),
                _incidentCard("Accident", Icons.directions_car),
              ],
            ),

            const SizedBox(height: 24),
              
            // DETAILS
            const Text(
              "Details",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detailsController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white), // Changed to white for better readability
              decoration: InputDecoration(
                hintText: "Describe what happened ...(optional)",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E2538),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ADD PHOTO
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text("Add Photo", style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint("Type: $selectedType");
                  debugPrint("Details: ${detailsController.text}");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Submit",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, 
                    fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incidentCard(String title, IconData icon) {
    final bool isSelected = selectedType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = title;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E2538),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}