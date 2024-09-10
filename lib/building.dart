import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;

class BuildingMap extends StatefulWidget {
  const BuildingMap({super.key});

  @override
  _BuildingMapState createState() => _BuildingMapState();
}

class _BuildingMapState extends State<BuildingMap> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {}; // สำหรับแสดงทุกตำแหน่ง
  Set<Marker> _driverMarkers = {}; // สำหรับแสดงตำแหน่งคนขับรถ
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _customIcon;

  final LatLng _center = const LatLng(17.2963234, 104.114407);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchBuildingLocations();
    _fetchPolylines();

    // โหลดไอคอนที่ปรับขนาดแล้ว
    _loadCustomIcon();

    // ตั้งค่าให้รีเฟรชเฉพาะตำแหน่งคนขับรถทุกๆ 2 วินาที
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchDriverLocations();
    });
  }

  @override
  void dispose() {
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
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          { "color": "#ff0000" },
          { "weight": 2.0 }
        ]
      }
    ]
    ''';
    mapController.setMapStyle(style);
  }

  // ฟังก์ชันสำหรับโหลดไอคอนที่ปรับขนาดเอง
  Future<void> _loadCustomIcon() async {
    final Uint8List markerIcon = await _resizeImage('assets/image/bus.png', 100);
    setState(() {
      _customIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  // ฟังก์ชันสำหรับปรับขนาดรูปภาพ
  Future<Uint8List> _resizeImage(String imagePath, int targetWidth) async {
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    
    final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ฟังก์ชันสำหรับดึงตำแหน่งอาคาร
  Future<void> _fetchBuildingLocations() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/buildings.php')); //https://chimmy007x.github.io/talaicsc.github.io/
      if (response.statusCode == 200) {                                                              //http://10.0.2.2/data_talaicsc/api/buildings.php  ใช้กับ emulater
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List buildings = data['buildings'];
          setState(() {
            _markers.addAll(buildings.map((building) {
              final LatLng position = _parseLatLng(building['location']);
              return Marker(
                markerId: MarkerId(building['building_id'].toString()),
                position: position,
                infoWindow: InfoWindow(
                  title: building['bname'],
                  snippet: 'Lat: ${position.latitude}, Lng: ${position.longitude}',
                ),
              );
            }).toSet());
          });
        }
      } else {
        print('Failed to load building locations');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // ฟังก์ชันสำหรับดึงตำแหน่งคนขับรถ (รีเฟรชทุกๆ 2 วินาที)
  Future<void> _fetchDriverLocations() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/getposition_drivers.php')); // https://github.com/chimmy007x/talaicsc.github.io.git
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List drivers = data['drivers'];

          setState(() {
            _driverMarkers.clear();
            drivers.forEach((driver) {
              if (driver['position'] != null) {
                final LatLng position = _parseLngLat(driver['position']);
                _driverMarkers.add(
                  Marker(
                    markerId: MarkerId(driver['number_id'].toString()),
                    position: position,
                    icon: _customIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: InfoWindow(
                      title: '${driver['fname']} ${driver['lname']}',
                      snippet: 'Bus ID: ${driver['bus_id']}',
                    ),
                  ),
                );
              }
            });
          });
        }
      } else {
        print('Failed to load driver locations');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลเส้นทาง (Polyline)
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

  // ฟังก์ชันสำหรับแยกค่าละติจูดและลองจิจูด
  LatLng _parseLatLng(String location) {
    final parts = location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    final lat = double.parse(parts[0]);
    final lng = double.parse(parts[1]);
    return LatLng(lat, lng);
  }

  LatLng _parseLngLat(String location) {
    final parts = location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    final lng = double.parse(parts[0]);
    final lat = double.parse(parts[1]);
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
      markers: _markers.union(_driverMarkers),
      polylines: _polylines,
    );
  }
}
