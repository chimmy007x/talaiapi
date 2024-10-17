import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // นำเข้าการใช้งาน Google Map
import 'ngrokhttp.dart';

class BusPage extends StatefulWidget {
  final String driverId;

  const BusPage({super.key, required this.driverId});

  @override
  _BusPageState createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  TextEditingController busIdController = TextEditingController();
  late Timer _timer;
  bool _isLoading = true;
  bool _isPositionUpdating = false; // ตัวแปรเพื่อจัดการการอัปเดตตำแหน่ง
  Position? _currentLocation;
  bool _hasShownDialog = false;
  late GoogleMapController _mapController;
  Marker? _currentPositionMarker;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _fetchPolylines();
    _fetchBuildingLocations();
  }

  @override
  void dispose() {
    if (_isPositionUpdating) {
      _timer.cancel(); // หยุดการอัปเดตตำแหน่งเมื่อยืนยันออกจากระบบ
    }
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied')),
      );
    }
  }

  Future<void> updateBusId() async {
    try {
      final response = await http.post(
        Uri.parse(NgrokHttp.getUrl('data_talaicsc/api/update_bus_id.php')),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'number_id': widget.driverId,
          'bus_id': busIdController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('บันทึกหมายเลขรถประจำทางเรียบร้อย')),
          );

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          _startUpdatingPosition(); // เริ่มการอัปเดตตำแหน่งหลังจากบันทึกเลขรถ
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('มีคนขับใส่เลขรถคันนี้ไปแล้ว: ${data['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to server')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred while saving data')),
      );
    }
  }

  Future<void> clearBusId() async {
    try {
      if (_isPositionUpdating) {
        _timer.cancel(); // หยุดการอัปเดตตำแหน่งเมื่อยืนยันออกจากระบบ
        _isPositionUpdating = false; // ปิดการอัปเดต
      }

      final response = await http.post(
        Uri.parse(NgrokHttp.getUrl('data_talaicsc/api/clear_bus_id.php')),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'driver_id': widget.driverId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          print('Bus ID and Position cleared successfully');
          Navigator.pushNamed(context, '/');
        } else {
          print(
              'Failed to clear Bus ID and Position: ${responseData['message']}');
        }
      } else {
        print('Failed to clear Bus ID and Position: Server error');
      }
    } catch (e) {
      print('Failed to clear Bus ID and Position: $e');
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการออกจากระบบ'),
          content: Text('คุณต้องการออกจากระบบหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // ปิดป็อปอัพหากไม่ต้องการออกจากระบบ
              },
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                clearBusId(); // ลบข้อมูล Bus ID และออกจากระบบ
                Navigator.of(context).pop(); // ปิดป็อปอัพ
              },
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  void _startUpdatingPosition() {
    _isPositionUpdating = true; // เปิดการอัปเดตตำแหน่ง
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = position;
          _isLoading = false;
        });
        await _updatePosition(position.latitude, position.longitude);
        _updateMapPosition(position.latitude, position.longitude);
        _fetchBuildingLocations();
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  Future<void> _updatePosition(double latitude, double longitude) async {
    final response = await http.post(
      Uri.parse(NgrokHttp.getUrl('data_talaicsc/api/update_position.php')),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'number_id': widget.driverId,
        'position': {
          'latitude': latitude,
          'longitude': longitude,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        print('Position updated successfully');
      } else {
        print('Failed to update position: ${data['message']}');
      }
    } else {
      print('Failed to connect to server');
    }
  }

  Future<BitmapDescriptor> _getCustomMarker() async {
  return await BitmapDescriptor.fromAssetImage(
    ImageConfiguration(devicePixelRatio: 10), // ลดความละเอียดลง
    'assets/image/bus.png',
  );
}

void _updateMapPosition(double latitude, double longitude) async {
  final BitmapDescriptor customIcon = await _getCustomMarker();

  final marker = Marker(
    markerId: MarkerId('current_position'),
    position: LatLng(latitude, longitude),
    icon: customIcon, // ใช้ไอคอนที่สร้างจากภาพ bus.png
    infoWindow: InfoWindow(title: 'ตำแหน่งปัจจุบัน'),
  );

  setState(() {
    _currentPositionMarker = marker;
    _markers.add(marker);
    _mapController.animateCamera(
      CameraUpdate.newLatLng(LatLng(latitude, longitude)),
    );
  });
}


  Future<void> _fetchPolylines() async {
    List<LatLng> polylinePoints = [
      LatLng(17.29646574581259, 104.11384165617754),
      LatLng(17.286166472068803, 104.10526099264818),
      LatLng(17.285160113773625, 104.10656464996325),
      LatLng(17.28906778568359, 104.10983808183268),
      LatLng(17.290097327213882, 104.10853454636624),
      LatLng(17.28790679605291, 104.11136840195036),
      LatLng(17.287927284341897, 104.1113469442789),
      LatLng(17.28755849479102, 104.11207650510816),
      LatLng(17.286882378695623, 104.11387894950988),
      LatLng(17.28473108364701, 104.11679719292484),
      LatLng(17.28456717442569, 104.11688302361061),
      LatLng(17.284239355545328, 104.11741946539685),
      LatLng(17.283604204797857, 104.11832068760373),
      LatLng(17.283647770957955, 104.11827478685242),
      LatLng(17.28346078332254, 104.11847089135152),
      LatLng(17.275305132216058, 104.13224988730042),
      LatLng(17.274465052894943, 104.13330391650781),
      LatLng(17.27430113453758, 104.13344339137223),
      LatLng(17.273973297385353, 104.13369015459389),
      LatLng(17.273573745067402, 104.13393691781555),
      LatLng(17.272528757966832, 104.13445190194071),
      LatLng(17.27231416345476, 104.1344865457032),
      LatLng(17.272058037967494, 104.1345294610461),
      LatLng(17.27175068691286, 104.13456164755327),
      LatLng(17.271217943848846, 104.13458310521665),
      LatLng(17.270787650267206, 104.13455091870946),
      LatLng(17.264507298530532, 104.13415395177022),
      LatLng(17.264527789422036, 104.13428269779891),
      LatLng(17.271381864944694, 104.13470112239784),
      LatLng(17.27171995175815, 104.13470112239784),
      LatLng(17.272099018048323, 104.13466893589067),
      LatLng(17.27277518841849, 104.13449727451908),
      LatLng(17.27279567839083, 104.13444363034046),
      LatLng(17.273482091176398, 104.13415395175949),
      LatLng(17.274055807339504, 104.13381062901631),
      LatLng(17.27448609330535, 104.13347803509677),
      LatLng(17.274762705171117, 104.13323127187512),
      LatLng(17.274988092310252, 104.13289867796765),
      LatLng(17.275367151896518, 104.1324051514962),
      LatLng(17.28331697837699, 104.11901556411367),
      LatLng(17.28356284382618, 104.11874734321253),
      LatLng(17.28372675394151, 104.11839329163361),
      LatLng(17.284341415587885, 104.11758862893483),
      LatLng(17.284474592004607, 104.11751352708477),
      LatLng(17.284751188883067, 104.11713801782268),
      LatLng(17.284781921842473, 104.11699854295826),
      LatLng(17.286584913180068, 104.11460601252192),
      LatLng(17.28868496605144, 104.11631189739235),
      LatLng(17.288859115699115, 104.11636554157097),
      LatLng(17.289002532932297, 104.11634408389952),
      LatLng(17.291184509966733, 104.11355458658231),
      LatLng(17.29454489819519, 104.1163203943194),
      LatLng(17.29396776235932, 104.11710529435597),
      LatLng(17.294381232999918, 104.11741203691143),
      LatLng(17.294958367539024, 104.11770073577544),
      LatLng(17.295389063776806, 104.11784508520745),
      LatLng(17.295673322762823, 104.11793530362196),
      LatLng(17.29569916446512, 104.1181788932885),
      LatLng(17.295897284062097, 104.1183051990415),
      LatLng(17.29569916446512, 104.1181788932885),
      LatLng(17.295647481056907, 104.11791725994297),
      LatLng(17.295182329729798, 104.11775486683197),
      LatLng(17.29466549354282, 104.11756540820245),
      LatLng(17.293950534413327, 104.11712333805534),
      LatLng(17.2951306461623, 104.11558962530388),
      LatLng(17.295811145139595, 104.11472352869916),
      LatLng(17.29602649238647, 104.11447091719315),
      LatLng(17.29648302772425, 104.11388449761601),
      LatLng(17.293104309055938, 104.11106577511917),
      LatLng(17.291191714723443, 104.11350270740498),
      LatLng(17.28993694455512, 104.11243096757018),
      LatLng(17.291873916237968, 104.11004507048287),
      LatLng(17.293104309045123, 104.11105301629664),
      LatLng(17.290180589932632, 104.10862884281859),
      LatLng(17.288316694708307, 104.11106577516303),
      LatLng(17.289924762251033, 104.11243096759539),
      LatLng(17.288316694708307, 104.11106577516303),
      LatLng(17.287841581138185, 104.11170371557391),
      LatLng(17.287707574529694, 104.1120226857684),
      LatLng(17.287110634815843, 104.11377064243415),
      LatLng(17.28657460566366, 104.11459996494533),
    ];

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('polyline_1'),
        points: polylinePoints,
        color: Colors.red,
        width: 2,
      ));
    });
  }

  Future<void> _fetchBuildingLocations() async {
    try {
      final response = await http.get(
        Uri.parse(NgrokHttp.getUrl(
            'data_talaicsc/api/getuser_position.php')), // แก้ไขตรงนี้
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);

        if (data['success']) {
          final List buildings = data['positions'];
          setState(() {
            // ลูปเพื่ออัปเดตเฉพาะตำแหน่งใหม่หรือที่เปลี่ยนแปลง
            for (var building in buildings) {
              final LatLng position = _parseLocation(building['location']);
              final String buildingId = building['position_id'].toString();

              // ตรวจสอบว่า marker นี้มีอยู่แล้วหรือไม่ ถ้ามีอยู่ให้ข้ามไป
              if (!_markers
                  .any((marker) => marker.markerId.value == buildingId)) {
                _markers.add(
                  Marker(
                    markerId: MarkerId(buildingId),
                    position: position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
                    infoWindow: InfoWindow(
                      title: 'Position ID: $buildingId',
                    ),
                  ),
                );
              }
            }
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

  LatLng _parseLocation(String location) {
    final parts =
        location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    final lng = double.parse(parts[0]);
    final lat = double.parse(parts[1]);
    return LatLng(lat, lng);
  }

  Future<void> _clearOldPositions() async {
    try {
      final response = await http.get(
        Uri.parse(NgrokHttp.getUrl(
            'data_talaicsc/api/delete_old_positions.php')), // แก้ไขตรงนี้
      );
      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() {
          _markers.clear();
        });
        _fetchBuildingLocations();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ลบตำแหน่งเก่าแล้ว')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ไม่สามารถลบตำแหน่งได้')));
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบตำแหน่ง')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasShownDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasShownDialog = true;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('ใส่หมายเลขรถประจำทาง'),
              content: TextField(
                controller: busIdController,
                decoration: InputDecoration(
                    hintText: 'กรุณาใส่หมายเลขรถประจำทางที่คุณขับ'),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    updateBusId();
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/image/logo.png',
          ),
        ),
        title: Row(
          children: const [
            Text('Talai Driver', style: TextStyle(fontSize: 25)),
            Spacer(),
            Icon(Icons.directions_bus),
            SizedBox(width: 10),
            Text(
              'KU CSC',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: _isLoading
                      ? const Text('กำลังโหลดตำแหน่ง...',
                          style: TextStyle(fontSize: 16))
                      : _currentLocation == null
                          ? const Text('ไม่สามารถดึงข้อมูลตำแหน่งได้',
                              style: TextStyle(fontSize: 16))
                          : Text(
                              'ตำแหน่งปัจจุบัน: ละติจูด ${_currentLocation!.latitude}, ลองจิจูด ${_currentLocation!.longitude}',
                              style: const TextStyle(fontSize: 16),
                            ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(17.2963234, 104.114407),
                zoom: 15.0,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showLogoutConfirmationDialog();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('ออกจากระบบ'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _clearOldPositions();
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('ลบข้อมูลตำแหน่ง'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
