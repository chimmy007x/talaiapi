import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'building.dart';

class UserPage extends StatefulWidget {
  final String fname;
  final String lname;
  final String status;
  final String nontriId;

  const UserPage({
    super.key, 
    required this.fname, 
    required this.lname, 
    required this.status,
    required this.nontriId,});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  LocationData? _currentLocation;
  LocationData? _lastSavedLocation;
  final Location _location = Location();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    final locationData = await _location.getLocation();
    setState(() {
      _currentLocation = locationData;
      _isLoading = false;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon1 - lon2);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _saveLocation() async {
  if (_currentLocation != null) {
    if (_lastSavedLocation != null) {
      double distance = _calculateDistance(
        _lastSavedLocation!.latitude!,
        _lastSavedLocation!.longitude!,
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      );

      if (distance < 10) {
        _showPopup(
            title: 'ตำแหน่งใกล้เกินไป',
            message: 'คุณได้บันทึกตำแหน่งในบริเวณนี้ไปแล้ว.');
        return;
      }
    }

    // ปรับการสร้าง positionId เพื่อป้องกันการซ้ำ
    final positionId = "POS_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/data_talaicsc/api/save_position.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'position_id': positionId,
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
          'nontri_id': widget.nontriId, // เพิ่ม nontri_id ที่คุณส่งมาจากหน้าแรก
        }),
      );

      final responseData = jsonDecode(response.body);
      if (responseData['success']) {
        _showPopup(
            title: 'กดเรียกรถสำเร็จ',
            message: 'บันทึกตำแหน่งการเรียกเรียบร้อยแล้ว.');
        _lastSavedLocation = _currentLocation;
      } else if (responseData['error'] == 'duplicate_position') {
        _showPopup(
            title: 'มีผู้ใช้อื่นได้ทำการกดเรียกรถแล้ว',
            message: 'กรุณารอในบริเวณนั้นสักครู่รถกำลังเดินทางมาในอีกไม่ช้า');
      } else {
        _showPopup(
            title: 'ข้อผิดพลาด',
            message: 'Error: ${responseData['message']}');
      }
    } catch (e) {
      _showPopup(
          title: 'มีผู้ใช้อื่นได้ทำการกดเรียกรถแล้ว',
          message: 'กรุณารอในบริเวณนั้นสักครู่รถกำลังเดินทางมาในอีกไม่ช้า');
    }
  }
}


  void _showPopup({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ออกจากระบบ'),
          content: Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
              },
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog ก่อน
                Navigator.pushNamedAndRemoveUntil(
                  context, '/', (Route<dynamic> route) => false); // กลับไปยังหน้าแรกและลบหน้าอื่นๆ
              },
              child: Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Talai'),
                Text(
                  'KU CSC',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Image.asset(
              'assets/image/logo.png',
              height: 40,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เมนู',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    '${widget.fname} ${widget.lname}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'สถานะ: ${widget.status}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Nontri ID: ${widget.nontriId}', // เพิ่มส่วนนี้เพื่อแสดง nontri_id
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('หน้าแรก'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.settings),
            //   title: const Text('user'),
            //   onTap: () {
            //     Navigator.pushNamed(context, '/user');
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('ร้องเรียน'),
              onTap: () {
                Navigator.pushNamed(
                  context, 
                  '/complaint',
                  arguments: {
                    'nontri_id': widget.nontriId, // ส่ง nontri_id ของผู้ใช้ที่เข้าสู่ระบบ
                  },
                );
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.info),
            //   title: const Text('เส้นทางการเดินรถ'),
            //   onTap: () {
            //     // Navigator.pushNamed(context, '/');
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('ข้อมูลคนขับรถ'),
              onTap: () {
                Navigator.pushNamed(context, '/driver');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ออกจากระบบ'),
              onTap: _confirmLogout,
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
                      ? const Text('กำลังโหลดตำแหน่ง...', style: TextStyle(fontSize: 16))
                      : _currentLocation == null
                          ? const Text('ไม่สามารถดึงข้อมูลตำแหน่งได้', style: TextStyle(fontSize: 16))
                          : Text(
                              'ตำแหน่งปัจจุบัน: ละติจูด ${_currentLocation!.latitude}, ลองจิจูด ${_currentLocation!.longitude}',
                              style: const TextStyle(fontSize: 16),
                            ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: const BuildingMap(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _saveLocation,
              child: Icon(Icons.location_on, color: Colors.red),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
