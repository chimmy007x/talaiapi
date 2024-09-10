import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverPage extends StatefulWidget {
  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  List<Map<String, dynamic>> drivers = [];

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/get_drivers.php'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          drivers = List<Map<String, dynamic>>.from(data['drivers']);
        });
      } else {
        // กรณีที่ไม่สำเร็จ
        print('Failed to load drivers: ${data['message']}');
      }
    } else {
      print('Server error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text('ข้อมูลคนขับรถ'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: drivers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                return Card(
                  color: const Color.fromARGB(255, 114, 178, 115), // กำหนดสีพื้นหลังของการ์ด
                  margin: EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.memory(
                            base64Decode(drivers[index]['photo']),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          'รถหมายเลข : ${drivers[index]['bus_id']}',
                          style: TextStyle(fontSize: 18.0),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'ชื่อ : ${drivers[index]['fname']} ${drivers[index]['lname']}',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
