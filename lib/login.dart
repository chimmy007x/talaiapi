import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';
import 'user_page.dart';
import 'officer_page.dart';
import 'bus_page.dart'; // import หน้า driver page

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2/data_talaicsc/api/login.php'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'nontri_id': _usernameController.text,
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success']) {
  if (data['page'] == 'UserPage') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserPage(
          fname: data['user']['fname'] ?? '',
          lname: data['user']['lname'] ?? '',
          status: data['user']['status'] ?? '',
          nontriId: data['user']['nontri_id'] ?? '', 
        ),
      ),
    );
  } else if (data['page'] == 'OfficerPage') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OfficerPage()),
    );
  } else if (data['page'] == 'BusPage') {
    // ตรวจสอบว่า number_id ไม่เป็น null
    final driverId = data['user']['number_id'];
    if (driverId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BusPage(driverId: driverId),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Driver ID not found in response.';
      });
    }
  }
} else {
  setState(() {
    _errorMessage = data['message'];
  });
}

      } else {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อกับเซิร์ฟเวอร์';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF4CAF50),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/image/logo.png',
                height: 100,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ใช้',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAED581),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'กลับสู่หน้าแรก',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
