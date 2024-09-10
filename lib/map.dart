import 'dart:async'; // เพิ่มไลบรารีนี้สำหรับใช้ Timer
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Mappage extends StatefulWidget {
  const Mappage({super.key});

  @override
  _MappageState createState() => _MappageState();
}

class _MappageState extends State<Mappage> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _timer;

  final LatLng _center = const LatLng(17.2963234, 104.114407); // กำหนดตำแหน่งเริ่มต้นบนแผนที่

  @override
  void initState() {
    super.initState();
    _fetchBuildingLocations();
    _fetchPolylines();

    // ตั้ง Timer เพื่อรีเฟรชทุกๆ 5 วินาที
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      _fetchBuildingLocations(); // รีเฟรชตำแหน่งทุกๆ 5 วินาที
    });
  }

  @override
  void dispose() {
    // ยกเลิก Timer เมื่อ widget ถูกลบออก
    _timer?.cancel();
    super.dispose();
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
      final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/getuser_position.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data); // ตรวจสอบข้อมูลที่ดึงมา

        if (data['success']) {
          final List buildings = data['positions'];
          setState(() {
            _markers = buildings.map((building) {
              final LatLng position = _parseLocation(building['location']);
              final String buildingId = building['position_id'].toString();

              // สร้าง Marker ด้วยไอคอนตำแหน่ง
              return Marker(
                markerId: MarkerId(buildingId),
                position: position,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // ใช้ Marker สีฟ้า
                infoWindow: InfoWindow(
                  title: 'Position ID: $buildingId',
                ),
              );
            }).toSet();
          });
        } else {
          print('No positions found');
        }
      } else {
        print('Failed to load building locations');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchPolylines() async {
    List<LatLng> polylinePoints = [
      LatLng(17.29646574581259, 104.11384165617754),
      LatLng(17.286166472068803, 104.10526099264818),
      LatLng(17.285160113773625, 104.10656464996325),
      LatLng(17.28906778568359, 104.10983808183268),
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
    final lng = double.parse(parts[0]); // ลองจิจูดมาก่อน
    final lat = double.parse(parts[1]); // ละติจูดมาตามหลัง
    return LatLng(lat, lng);
  }

  Future<void> _clearOldPositions() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/delete_old_positions.php'));
      final data = jsonDecode(response.body);

      if (data['success']) {
        _fetchBuildingLocations(); // ดึงข้อมูลตำแหน่งใหม่หลังจากลบข้อมูลเก่าแล้ว
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบตำแหน่งเก่าแล้ว'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถลบตำแหน่งได้'))
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการลบตำแหน่ง'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แผนที่เรียกรถ'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // ปุ่มย้อนกลับ
          },
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 15.0,
            ),
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width / 2 -
                28, // คำนวณให้ปุ่มอยู่ตรงกลาง (ขนาดของ FloatingActionButton คือ 56 ดังนั้นต้องลบครึ่งนึงเพื่อให้ปุ่มอยู่ตรงกลาง)
            child: FloatingActionButton(
              onPressed: _clearOldPositions, // เมื่อกดจะลบข้อมูลเก่าจากฐานข้อมูล
              child: Icon(Icons.clear),
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
