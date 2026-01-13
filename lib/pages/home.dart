import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:safestep/pages/report.dart';
import 'package:safestep/pages/alerts.dart';
import 'package:safestep/pages/profile.dart';
import 'package:safestep/widgets/sos_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  LatLng _currentLocation = const LatLng(9.03, 38.74);
  List<LatLng> _routePoints = [];

  String _currentAddress = "Locating...";
  bool _isLoading = true;
  bool _showRouteInputs = false;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot>? _emergencySubscription;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _startEmergencyListener();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _emergencySubscription?.cancel();
    _startController.dispose();
    _destController.dispose();
    super.dispose();
  }

  // --- EMERGENCY LISTENER ---
  void _startEmergencyListener() {
    _emergencySubscription = FirebaseFirestore.instance
        .collection('emergency_alerts')
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (data['userId'] != user?.uid) {
            _showTopNotification(data, change.doc.id);
          }
        }
      }
    });
  }

  void _showTopNotification(Map<String, dynamic> data, String docId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 70, left: 10, right: 10),
        content: Text("🚨 SOS: ${data['userName']} needs help!"),
        action: SnackBarAction(
          label: "VIEW",
          textColor: Colors.white,
          onPressed: () => _showEmergencyDetails(data, docId),
        ),
      ),
    );
  }

  // --- MARKERS LAYER ---
  Widget _buildMarkersLayer() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, reportSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('emergency_alerts')
              .where('status', whereIn: const ['ACTIVE', 'RESPONDING']) 
              .snapshots(),
          builder: (context, sosSnap) {
            List<Marker> markers = [];

            markers.add(Marker(
              point: _currentLocation,
              width: 60, height: 60,
              child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
            ));

            if (reportSnap.hasData) {
              for (var doc in reportSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final GeoPoint loc = data['location'];
                markers.add(Marker(
                  point: LatLng(loc.latitude, loc.longitude),
                  child: GestureDetector(
                    onTap: () => _showReportDetails(data),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 30),
                  ),
                ));
              }
            }

            if (sosSnap.hasData) {
              for (var doc in sosSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final GeoPoint loc = data['location'];
                final bool isResponding = data['status'] == 'RESPONDING';
                
                markers.add(Marker(
                  point: LatLng(loc.latitude, loc.longitude),
                  width: 50, height: 50,
                  child: GestureDetector(
                    onTap: () => _showEmergencyDetails(data, doc.id),
                    child: Icon(
                      Icons.emergency, 
                      color: isResponding ? Colors.green : Colors.red, 
                      size: 40
                    ),
                  ),
                ));
              }
            }
            return MarkerLayer(markers: markers);
          },
        );
      },
    );
  }

  // --- UI: BOTTOM SHEETS ---
  void _showReportDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data['type'] ?? "Report", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(data['details'] ?? "No description.", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDetails(Map<String, dynamic> data, String docId) {
    final bool isAlreadyResponding = data['status'] == 'RESPONDING';

    showModalBottomSheet(
      context: context,
      backgroundColor: isAlreadyResponding ? const Color(0xFF064e3b) : const Color(0xFF450a0a),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlreadyResponding ? Icons.verified_user : Icons.bolt, 
              color: isAlreadyResponding ? Colors.greenAccent : Colors.yellowAccent, 
              size: 50
            ),
            const SizedBox(height: 10),
            Text("${data['userName']} needs help", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
              isAlreadyResponding ? "Help is already on the way." : "Are you able to assist this person?", 
              style: const TextStyle(color: Colors.white60)
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE", style: TextStyle(color: Colors.white)))),
                if (!isAlreadyResponding) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _acknowledgeEmergency(data, docId),
                      child: const Text("I'M ON MY WAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTION: ACKNOWLEDGE SOS ---
  Future<void> _acknowledgeEmergency(Map<String, dynamic> data, String docId) async {
    final GeoPoint loc = data['location'];
    final LatLng victimLoc = LatLng(loc.latitude, loc.longitude);

    await FirebaseFirestore.instance.collection('emergency_alerts').doc(docId).update({
      'status': 'RESPONDING',
      'responderId': user?.uid,
      'responderName': user?.displayName ?? "A Rescuer",
    });

    if (mounted) {
      Navigator.pop(context);
      setState(() {
        _routePoints = [_currentLocation, victimLoc];
      });

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_currentLocation, victimLoc]),
          padding: const EdgeInsets.all(80),
        ),
      );
    }
  }

  // --- LOCATION SERVICES ---
  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _mapController.move(_currentLocation, 17);
      _updateAddress(position.latitude, position.longitude);
    }

    _positionStream = Geolocator.getPositionStream().listen((pos) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          if (_routePoints.isNotEmpty) _routePoints[0] = _currentLocation;
        });
      }
    });
  }

  Future<void> _updateAddress(double lat, double lon) async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(lat, lon);
      if (p.isNotEmpty) setState(() => _currentAddress = p[0].street ?? "Unknown Street");
    } catch (_) {}
  }

  Future<void> _findRoute() async {
    try {
      List<Location> s = await locationFromAddress(_startController.text);
      List<Location> d = await locationFromAddress(_destController.text);
      if (s.isNotEmpty && d.isNotEmpty) {
        setState(() {
          _routePoints = [LatLng(s.first.latitude, s.first.longitude), LatLng(d.first.latitude, d.first.longitude)];
          _showRouteInputs = false;
        });
        _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(_routePoints), padding: const EdgeInsets.all(50)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Route not found")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLocation, initialZoom: 17),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileBuilder: (context, widget, tile) => ColorFiltered(
                  colorFilter: const ColorFilter.matrix([0.21, 0.71, 0.07, 0, -160, 0.21, 0.71, 0.07, 0, -160, 0.21, 0.71, 0.07, 0, -160, 0, 0, 0, 1, 0]),
                  child: widget,
                ),
              ),
              if (_routePoints.isNotEmpty) 
                PolylineLayer(polylines: [
                  Polyline(points: _routePoints, color: Colors.blueAccent, strokeWidth: 5, strokeCap: StrokeCap.round)
                ]),
              _buildMarkersLayer(),
            ],
          ),

          // --- ZOOM BUTTONS (RESTORED) ---
          Positioned(
            right: 20,
            bottom: 220,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  backgroundColor: const Color(0xFF1E293B),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  backgroundColor: const Color(0xFF1E293B),
                  child: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(children: [
              _buildHeader(),
              if (_showRouteInputs) _buildRouteSearchBox(),
              const Spacer(),
              _buildSafeCircleStream(),
              const SOSButton(),
              const SizedBox(height: 10),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showRouteInputs = !_showRouteInputs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
              child: Row(children: [
                const Icon(Icons.location_on, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(_currentAddress, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
              ]),
            ),
          ),
          FloatingActionButton.small(
            heroTag: "campaign_btn",
            backgroundColor: const Color(0xFF1E293B),
            child: const Icon(Icons.campaign, color: Colors.blueAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeCircleStream() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 90,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('contacts').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _avatar("Add", Icons.add, isAdd: true),
              ...docs.map((doc) => _avatar(doc['name'], Icons.person)),
            ],
          );
        },
      ),
    );
  }

  Widget _avatar(String name, IconData icon, {bool isAdd = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(children: [
        CircleAvatar(radius: 28, backgroundColor: isAdd ? Colors.white10 : Colors.blue.withOpacity(0.15), child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }

  // --- ICONS RESTORED HERE ---
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white38,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"), 
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.add_location_alt_outlined), label: "Report"), 
        BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: "Profile"),
      ],
      onTap: (i) {
        if (i == 0) return;
        Widget p = i == 1 ? const AlertsPage() : i == 2 ? const ReportPage() : const ProfilePage();
        Navigator.push(context, MaterialPageRoute(builder: (_) => p));
      },
    );
  }

  Widget _buildRouteSearchBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Column(children: [
        TextField(controller: _startController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Starting point...", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none)),
        const Divider(color: Colors.white10),
        TextField(controller: _destController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Where to?", hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none)),
        const SizedBox(height: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _findRoute, 
          child: const Text("Show Route", style: TextStyle(color: Colors.white))
        ),
      ]),
    );
  }
}