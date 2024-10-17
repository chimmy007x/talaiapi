import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'building.dart';
import 'dart:async';
import 'ngrokhttp.dart';

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
    required this.nontriId,
  });

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  LocationData? _currentLocation;
  LocationData? _lastSavedLocation;
  final Location _location = Location();
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getLocation();
    // เรียก _getLocation ทุกๆ 1 วินาที
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      _getLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิก Timer เมื่อปิดหน้าจอ
    super.dispose();
  }

  Future<void> _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // ตรวจสอบว่าเปิดการใช้งาน Location หรือไม่
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

    // ตรวจสอบว่าได้รับอนุญาตการใช้งาน Location หรือไม่
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

    // รับข้อมูลตำแหน่งปัจจุบัน
    final locationData = await _location.getLocation();
    setState(() {
      _currentLocation = locationData;  // อัปเดตข้อมูลตำแหน่ง
      _isLoading = false;               // ปิดสถานะการโหลด
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // กำหนดค่า R เป็นรัศมีของโลกในหน่วยเมตร (6371000 เมตร)
    const double R = 6371000;

    // คำนวณการเปลี่ยนแปลงของละติจูดระหว่างสองจุด (แปลงจากองศาเป็นเรเดียน)
    final double dLat = _degreesToRadians(lat2 - lat1);

    // คำนวณการเปลี่ยนแปลงของลองจิจูดระหว่างสองจุด (แปลงจากองศาเป็นเรเดียน)
    final double dLon = _degreesToRadians(lon1 - lon2);

    // ใช้สูตร Haversine คำนวณความโค้งของระยะทางระหว่างสองจุด
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
        cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) *
        sin(dLon / 2);

    // คำนวณมุมระหว่างสองจุดจากค่า a
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // คืนค่าระยะทางโดยคูณมุมกับรัศมีโลก (R) ผลลัพธ์จะเป็นระยะทางในหน่วยเมตร
    return R * c;
}

// ฟังก์ชันแปลงองศาเป็นเรเดียน
double _degreesToRadians(double degrees) {
    // แปลงองศาเป็นเรเดียนโดยใช้สูตร degrees * pi / 180
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

            //การคำนวณระยะทาง 10 เมตรในโค้ดนี้เกิดขึ้นในฟังก์ชัน _saveLocation() โดยใช้ฟังก์ชัน _calculateDistance() ซึ่งคำนวณระยะทางระหว่างตำแหน่งปัจจุบันและตำแหน่งที่บันทึกไว้ล่าสุด (_lastSavedLocation) ในหน่วยเมตร
        if (distance < 10) {
          _showPopup(
              title: 'ตำแหน่งใกล้เกินไป',
              message: 'มีการกดเรียกรถในบริเวณนี้ไปแล้ว.');
          return;
        }
      }

      // ปรับการสร้าง positionId เพื่อป้องกันการซ้ำ
      final positionId =
          "POS_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";

      try {
        final response = await http.post(
          Uri.parse(NgrokHttp.getUrl('data_talaicsc/api/save_position.php')),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'position_id': positionId,
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
            'nontri_id': widget.nontriId,
          }),
        );

        final responseData = jsonDecode(response.body);

        // ตรวจสอบสถานะของการตอบสนอง
        if (response.statusCode == 200) {
          // ตรวจสอบความสำเร็จภายใน JSON
          if (responseData['success']) {
            _showPopup(
              title: 'กดเรียกรถสำเร็จ',
              message: 'บันทึกตำแหน่งการเรียกเรียบร้อยแล้ว.',
            );
            _lastSavedLocation = _currentLocation;
          } else {
            // แสดงข้อความจากเซิร์ฟเวอร์หากไม่สำเร็จ
            _showPopup(
              title: 'มีผู้ใช้อื่นได้กดเรียกรถแล้ว',
              message: responseData['message'] ?? 'Unknown error occurred.',
            );
          }
        } else {
          // เมื่อสถานะไม่ใช่ 200 แสดงข้อความแสดงข้อผิดพลาด
          _showPopup(
            title: 'เกิดข้อผิดพลาด',
            message:
                'สถานะเซิร์ฟเวอร์: ${response.statusCode}. กรุณาลองอีกครั้ง.',
          );
        }
      } catch (e) {
        // จัดการข้อผิดพลาดที่เกิดขึ้นระหว่างการเชื่อมต่อ
        _showPopup(
          title: 'คุณกดเรียกรถแล้ว',
          message: 'คนขับรถได้เห็นการเรียกรถแล้วกรุณารอสักครู่.',
        );
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
                Navigator.pushReplacementNamed(
                  context,
                  '/', // หรือระบุชื่อหน้าที่ต้องการกลับไป เช่น หน้าเข้าสู่ระบบ
                ); // ใช้ pushReplacement เพื่อแทนที่หน้าจอปัจจุบัน
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
                Text(
                  'Talai KU CSC',
                  style: TextStyle(
                    fontSize: 30,
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
