import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Updated
import 'package:latlong2/latlong.dart'; // Added for coordinates

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Use MapController from flutter_map to handle zoom/movement
  final MapController _mapController = MapController(); 

  // Placeholder coordinates
  final LatLng _currentLocation = const LatLng(40.7128, -74.0060);

  // 🔹 Dynamic route data
  int estimatedMinutes = 12;
  double distanceMiles = 0.6;
  String routeName = "Golagol 22";
  bool isWellLit = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ───────── OPENSTREETMAP LAYER ─────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safestep.app',
              ),
              // Marker for the user
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF2563EB),
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ───────── TOP BAR ─────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _buildTopBar(context),
            ),
          ),

          // ───────── MAP CONTROLS ─────────
          Positioned(
            right: 16,
            top: 120,
            child: _buildMapControls(),
          ),

          // ───────── BOTTOM PANEL ─────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  // ───────── TOP BAR ─────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleAvatar(
          backgroundColor: Colors.black54,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Walking Home",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "SAFE ROUTE ACTIVE",
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
        TextButton(
          onPressed: () => debugPrint("End trip"),
          child: const Text(
            "End Trip",
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  // ───────── MAP CONTROLS ─────────
  Widget _buildMapControls() {
    return Column(
      children: [
        _mapButton(Icons.add, () {
          // New way to zoom in
          _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
        }),
        const SizedBox(height: 10),
        _mapButton(Icons.remove, () {
          // New way to zoom out
          _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
        }),
        const SizedBox(height: 10),
        _mapButton(Icons.navigation, () {
          // New way to re-center
          _mapController.move(_currentLocation, 14);
        }),
        const SizedBox(height: 10),
        _mapButton(Icons.lock, () {
          debugPrint("Safety lock");
        }),
      ],
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return CircleAvatar(
      backgroundColor: Colors.black54,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  // ───────── BOTTOM PANEL ─────────
  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "$estimatedMinutes",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text("min", style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 12),
              Text(
                "• ${distanceMiles.toStringAsFixed(1)} mi",
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "via $routeName (${isWellLit ? "Well-lit route" : "Low lighting"})",
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => debugPrint("Share live location"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text("Share Live Location", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onLongPress: () => debugPrint("SOS ACTIVATED"),
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  "SOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}