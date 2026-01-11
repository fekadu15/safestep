import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Updated
import 'package:latlong2/latlong.dart'; // Added for coordinates

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Placeholder center
  final LatLng _mapCenter = const LatLng(0.0, 0.0);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. MAP LAYER (Updated to OpenStreetMap)
          FlutterMap(
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safestep.app',
              ),
              // Marker for User Location
              MarkerLayer(
                markers: [
                  Marker(
                    point: _mapCenter,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_history,
                      color: Colors.blueAccent,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. TOP OVERLAY
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildTopProfileBar(),
                  const SizedBox(height: 15),
                  _buildSearchCard(),
                ],
              ),
            ),
          ),

          // 3. BOTTOM OVERLAY (SOS PANEL)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomPanel(),
          ),
        ],
      ),

      // ✅ BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          debugPrint("Tapped tab: $index");
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  // ───────── TOP BAR ─────────
  Widget _buildTopProfileBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            children: [
              CircleAvatar(radius: 15, backgroundColor: Colors.orange),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("CURRENT LOCATION", style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text("Fetching location...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
        const CircleAvatar(
          backgroundColor: Colors.black54,
          child: Icon(Icons.shield, color: Colors.blueAccent),
        ),
      ],
    );
  }

  // ───────── SEARCH / ROUTE CARD ─────────
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.green),
              SizedBox(width: 10),
              Text("Safe route suggestion", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white54, size: 16),
              Text(" Calculating...  •  ", style: TextStyle(color: Colors.white54)),
              Icon(Icons.wb_sunny_outlined, color: Colors.green, size: 16),
              Text(" Well-lit", style: TextStyle(color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  // ───────── BOTTOM PANEL ─────────
  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Share Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          _buildTrustedContacts(),
          const SizedBox(height: 20),
          GestureDetector(
            onLongPress: () => debugPrint("SOS ACTIVATED"),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: const Center(
                child: Text("HOLD FOR SOS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustedContacts() {
    return const Row(
      children: [
        CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.add, color: Colors.white)),
        SizedBox(width: 15),
        CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
        SizedBox(width: 15),
        CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
      ],
    );
  }
}