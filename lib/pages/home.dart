import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String _currentAddress = " where to go...";
  bool _isLoading = true;
  bool _showRouteInputs = false;
  bool _isCalculatingRoute = false;

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

  // --- ADD CONTACT DIALOG (Restored & Integrated) ---
  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Safe Contact", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Name",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Phone Number",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('contacts')
                    .add({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  // --- SAFE CIRCLE ACTIONS (CALL & DELETE) ---
  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _confirmDeleteContact(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Remove $name?", style: const TextStyle(color: Colors.white)),
        content: const Text("Remove this person from your Safe Circle?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('contacts').doc(docId).delete();
              Navigator.pop(context);
            }, 
            child: const Text("REMOVE", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // --- STREET-FOLLOWING ROUTE LOGIC (OSRM) ---
  Future<void> _getStreetRoute(LatLng start, LatLng end) async {
    setState(() => _isCalculatingRoute = true);
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coords = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        });
      }
    } catch (e) {
      debugPrint("Routing Error: $e");
      setState(() => _routePoints = [start, end]);
    } finally {
      setState(() => _isCalculatingRoute = false);
    }
  }

  // --- SAFETY BRAIN: CHECK FOR NEARBY HAZARDS ---
  void _checkRouteSafety(LatLng destination) {
    FirebaseFirestore.instance.collection('reports').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        GeoPoint hazardLoc = data['location'];
        
        double distance = Geolocator.distanceBetween(
          destination.latitude, destination.longitude, 
          hazardLoc.latitude, hazardLoc.longitude
        );

        if (distance < 500) { 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange.shade900,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 10, right: 10),
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text("⚠️ Safety Warning: Route ends near a ${data['type']}!")),
                ],
              ),
              duration: const Duration(seconds: 6),
            )
          );
          break;
        }
      }
    });
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
              .where('status', whereIn: const ['ACTIVE', 'RESPONDING']).snapshots(),
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
                    child: Icon(Icons.emergency, color: isResponding ? Colors.green : Colors.red, size: 40),
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
            Icon(isAlreadyResponding ? Icons.verified_user : Icons.bolt,
                color: isAlreadyResponding ? Colors.greenAccent : Colors.yellowAccent, size: 50),
            const SizedBox(height: 10),
            Text("${data['userName']} needs help", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(isAlreadyResponding ? "Help is already on the way." : "Are you able to assist this person?",
                style: const TextStyle(color: Colors.white60)),
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
      await _getStreetRoute(_currentLocation, victimLoc); 
      _checkRouteSafety(victimLoc); 

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_currentLocation, victimLoc]),
          padding: const EdgeInsets.all(80),
        ),
      );
    }
  }

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
      if (mounted) setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
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
        final start = LatLng(s.first.latitude, s.first.longitude);
        final end = LatLng(d.first.latitude, d.first.longitude);
        await _getStreetRoute(start, end);
        _checkRouteSafety(end);
        setState(() => _showRouteInputs = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _currentLocation, initialZoom: 17),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileBuilder: (context, widget, tile) => ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.21, 0.71, 0.07, 0, -160, 
                          0.21, 0.71, 0.07, 0, -160, 
                          0.21, 0.71, 0.07, 0, -160, 
                          0, 0, 0, 1, 0
                        ]),
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

                if (_isCalculatingRoute)
                  const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),

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
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final photoUrl = userData?['photoUrl'];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1E293B),
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                );
              }),
        ],
      ),
    );
  }

  Widget _buildSafeCircleStream() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('contacts').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _avatar("Add", Icons.add, isAdd: true, onTap: _showAddContactDialog),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _avatar(
                  data['name'] ?? "User", 
                  Icons.person,
                  onTap: () => _makePhoneCall(data['phone']),
                  onLongPress: () => _confirmDeleteContact(doc.id, data['name'] ?? "Contact"),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _avatar(String name, IconData icon, {bool isAdd = false, VoidCallback? onTap, VoidCallback? onLongPress}) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(children: [
          CircleAvatar(
            radius: 28, 
            backgroundColor: isAdd ? Colors.white10 : Colors.blue.withOpacity(0.15), 
            child: Icon(icon, color: isAdd ? Colors.white : Colors.blueAccent)
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ),
    );
  }

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
            child: const Text("Show Route", style: TextStyle(color: Colors.white))),
      ]),
    );
  }
}