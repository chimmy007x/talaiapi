import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
  Position? _currentLocation;
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _timer.cancel();
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
    final response = await http.post(
      Uri.parse('http://10.0.2.2/data_talaicsc/api/update_bus_id.php'),
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
        Navigator.of(context).pop();
        _startUpdatingPosition(); // เริ่มการอัปเดตตำแหน่งหลังจากกรอก Bus ID แล้ว
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('มีคนขับใส่เลขรถคันนี้ไปแล้ว: ${data['message']}')),
        );
      }
      _hasShownDialog = true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to server')),
      );
    }
  }

  Future<void> clearBusId() async {
    try {
      _timer.cancel(); // ยกเลิก Timer ก่อนที่จะลบข้อมูลเพื่อหยุดการอัปเดตตำแหน่ง

      final response = await http.post(
        Uri.parse('http://10.0.2.2/data_talaicsc/api/clear_bus_id.php'),
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
          print('Failed to clear Bus ID and Position: ${responseData['message']}');
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
                Navigator.of(context).pop(); // ปิดป็อปอัพหากไม่ต้องการออกจากระบบ
              },
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                clearBusId(); // เรียกฟังก์ชัน clearBusId เพื่อออกจากระบบ
                Navigator.of(context).pop(); // ปิดป็อปอัพหลังจากยืนยันออกจากระบบ
              },
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  void _startUpdatingPosition() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = position;
          _isLoading = false;
        });
        await _updatePosition(position.latitude, position.longitude);
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  Future<void> _updatePosition(double latitude, double longitude) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/data_talaicsc/api/update_position.php'),
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

  @override
  Widget build(BuildContext context) {
    if (!_hasShownDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('ใส่หมายเลขรถประจำทาง'),
              content: TextField(
                controller: busIdController,
                decoration: InputDecoration(hintText: 'กรุณาใส่หมายเลขรถประจำทางที่คุณขับ'),
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
            Text('Talai', style: TextStyle(fontSize: 16)),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGridButton(
                  context: context,
                  icon: Icons.report,
                  label: 'ตำแหน่งเรียกรถ',
                  onTap: () {
                    Navigator.pushNamed(context, '/map');
                  },
                ),
                _buildGridButton(
                  context: context,
                  icon: Icons.person,
                  label: 'ข้อมูลคนใช้บริการ',
                  onTap: () {
                    // เพิ่มฟังก์ชันการทำงานที่ต้องการเมื่อกดปุ่มนี้
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutConfirmationDialog(); // เรียกฟังก์ชันนี้เมื่อกดปุ่มออกจากระบบ
              },
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
