import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuildingPage extends StatelessWidget {
  const BuildingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('อาคารเรียน'),
      ),
      body: const BuildingMap(),
    );
  }
}

class BuildingMap extends StatefulWidget {
  const BuildingMap({super.key});

  @override
  _BuildingMapState createState() => _BuildingMapState();
}

class _BuildingMapState extends State<BuildingMap> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final LatLng _center = const LatLng(17.2963234, 104.114407); // กำหนดตำแหน่งเริ่มต้นบนแผนที่

  @override
  void initState() {
    super.initState();
    _fetchBuildingLocations();
    _fetchPolylines();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _setMapStyle();
  }

  Future<void> _setMapStyle() async {
    String style = '''
    [
      {
        "featureType": "poi",
        "stylers": [
          { "visibility": "off" }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          { "color": "#000" },
          { "weight": 1.5 }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels",
        "stylers": [
          { "visibility": "simplified" }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          { "color": "#ff0000" },
          { "weight": 2.0 }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels",
        "stylers": [
          { "visibility": "simplified" }
        ]
      }
    ]
    ''';
    mapController.setMapStyle(style);
  }

  Future<void> _fetchBuildingLocations() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/buildings.php')); // เปลี่ยน URL
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List buildings = data['buildings'];
          setState(() {
            _markers = buildings.map((building) {
              final LatLng position = _parseLocation(building['location']);
              return Marker(
                markerId: MarkerId(building['building_id'].toString()),
                position: position,
                infoWindow: InfoWindow(
                  title: building['bname'],
                ),
              );
            }).toSet();
          });
        }
      } else {
        print('Failed to load building locations');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchPolylines() async {
    // เพิ่มโค้ดเพื่อดึงข้อมูลเส้นทางจาก API หรือสร้างข้อมูลเส้นทางเอง
    // ตัวอย่างนี้สร้างเส้นทางจากจุดต่าง ๆ แบบง่าย ๆ
    List<LatLng> polylinePoints = [
      LatLng(17.29646574581259, 104.11384165617754),
      LatLng(17.286166472068803, 104.10526099264818),
      LatLng(17.285160113773625, 104.10656464996325),
      LatLng(17.28906778568359, 104.10983808183268),
      // LatLng(17.263881224910595, 104.1340678235925),
      // เพิ่มตำแหน่งที่ต้องการ
    ];

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('polyline_1'),
        points: polylinePoints,
        color: Colors.red,
        width: 5,
      ));
    });
  }

  LatLng _parseLocation(String location) {
    final parts = location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    final lat = double.parse(parts[0]);
    final lng = double.parse(parts[1]);
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 15.0,
      ),
      markers: _markers,
      polylines: _polylines,
    );
  }
}
