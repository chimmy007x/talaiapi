import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditDriverPage extends StatefulWidget {
  @override
  _EditDriverPageState createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  List<Map<String, dynamic>> drivers = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  // ดึงข้อมูลคนขับรถจากฐานข้อมูล
  Future<void> fetchDrivers() async {
    final response = await http
        .get(Uri.parse('http://10.0.2.2/data_talaicsc/api/get_drivers.php'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          drivers = List<Map<String, dynamic>>.from(data['drivers']);
        });
      } else {
        print('Failed to load drivers: ${data['message']}');
      }
    } else {
      print('Server error: ${response.statusCode}');
    }
  }

  // อัปโหลดรูปภาพใหม่
  Future<void> selectImage(Map<String, dynamic> driver) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        driver['photo'] =
            base64Encode(bytes); // เก็บรูปภาพที่อัปโหลดในรูปแบบ base64
      });
    }
  }

  // เพิ่มข้อมูลคนขับรถใหม่
  Future<void> addDriver(Map<String, dynamic> newDriver) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/data_talaicsc/api/add_driver.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'number_id': newDriver['number_id'], // รหัสบัตรประชาชน
        'password': newDriver['password'], // รหัสผ่าน
        'fname': newDriver['fname'], // ชื่อ
        'lname': newDriver['lname'], // นามสกุล
        'photo': newDriver['photo'], // รูปภาพ (base64)
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เพิ่มคนขับรถสำเร็จ')));
        fetchDrivers(); // รีโหลดข้อมูลใหม่หลังจากเพิ่มข้อมูล
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เพิ่มคนขับรถไม่สำเร็จ: ${data['message']}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.statusCode}')));
    }
  }

  // บันทึกการแก้ไขข้อมูลคนขับรถ
  Future<void> saveDriver(Map<String, dynamic> driver) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/data_talaicsc/api/update_driver.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode({
        'number_id': driver['number_id'], // รหัสบัตรประชาชน
        'password': driver['password'], // รหัสผ่าน
        'fname': driver['fname'], // ชื่อ
        'lname': driver['lname'], // นามสกุล
        'photo': driver['photo'], // รูปภาพ (base64)
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('บันทึกข้อมูลไม่สำเร็จ: ${data['message']}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')));
    }
  }

  // ฟังก์ชันลบข้อมูลคนขับรถ
  Future<void> deleteDriver(String numberId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2/data_talaicsc/api/delete_driver.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode({
        'number_id': numberId, // ส่ง number_id เพื่อทำการลบ
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ลบข้อมูลสำเร็จ')));
        fetchDrivers(); // รีโหลดข้อมูลคนขับรถใหม่หลังจากลบเสร็จ
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ลบข้อมูลไม่สำเร็จ: ${data['message']}')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.statusCode}')));
    }
  }

  // ป็อปอัพยืนยันการลบข้อมูล
  void showDeleteConfirmationDialog(String numberId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ยืนยันการลบ'),
          content: Text('คุณแน่ใจหรือว่าต้องการลบข้อมูลคนขับรถนี้?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิดป็อปอัพหากยกเลิกการลบ
              },
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteDriver(numberId); // เรียกฟังก์ชันลบข้อมูล
                Navigator.of(context).pop(); // ปิดป็อปอัพหลังจากลบข้อมูลเสร็จ
              },
              child: Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  // แสดงป็อบอัพให้กรอกข้อมูลใหม่
  void showAddDriverDialog() {
    Map<String, dynamic> newDriver = {
      'number_id': '',
      'password': '',
      'fname': '',
      'lname': '',
      'photo': null,
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('เพิ่มคนขับรถใหม่'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'รหัสบัตรประชาชน'),
                  onChanged: (value) {
                    newDriver['number_id'] = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'รหัสผ่าน'),
                  obscureText: true,
                  onChanged: (value) {
                    newDriver['password'] = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'ชื่อ'),
                  onChanged: (value) {
                    newDriver['fname'] = value;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'นามสกุล'),
                  onChanged: (value) {
                    newDriver['lname'] = value;
                  },
                ),
                SizedBox(height: 16),
                newDriver['photo'] != null
                    ? Image.memory(
                        base64Decode(newDriver['photo']),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.person, size: 100), // ใช้ไอคอนแทนรูปภาพ
                TextButton(
                  onPressed: () async {
                    final XFile? image =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        newDriver['photo'] = base64Encode(bytes);
                      });
                    }
                  },
                  child: Text('อัปโหลดรูปภาพ'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                addDriver(newDriver);
                Navigator.of(context).pop(); // ปิดป็อบอัพเมื่อบันทึกสำเร็จ
              },
              child: Text('บันทึก'),
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
        title: Text('แก้ไขข้อมูลคนขับรถ'),
      ),
      body: drivers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final driver = drivers[index];
                return Card(
                  color: const Color.fromARGB(255, 114, 178, 115),
                  margin: EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFormField(
                          initialValue: driver['number_id'],
                          decoration:
                              InputDecoration(labelText: 'รหัสบัตรประชาชน'),
                          readOnly: true, // ทำให้ช่องนี้ไม่สามารถแก้ไขได้
                          onChanged: (value) {
                            // ไม่จำเป็นต้องใช้งานส่วนนี้ถ้าไม่ต้องการให้มีการเปลี่ยนแปลงค่า
                          },
                        ),
                        //  TextFormField(
                        //   initialValue: driver['number_id'],
                        //   decoration:
                        //       InputDecoration(labelText: 'รหัสบัตรประชาชน'),
                        //   onChanged: (value) {
                        //     driver['number_id'] = value;
                        //   },
                        // ),
                        
                        TextFormField(
                          initialValue: driver['password'],
                          decoration: InputDecoration(labelText: 'รหัสผ่าน'),
                          obscureText: true,
                          onChanged: (value) {
                            driver['password'] = value;
                          },
                        ),
                        TextFormField(
                          initialValue: driver['fname'],
                          decoration: InputDecoration(labelText: 'ชื่อ'),
                          onChanged: (value) {
                            driver['fname'] = value;
                          },
                        ),
                        TextFormField(
                          initialValue: driver['lname'],
                          decoration: InputDecoration(labelText: 'นามสกุล'),
                          onChanged: (value) {
                            driver['lname'] = value;
                          },
                        ),
                        SizedBox(height: 16),
                        driver['photo'] != null
                            ? Image.memory(
                                base64Decode(driver['photo']),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.person,
                                size: 100), // แสดงไอคอนผู้ใช้แทนรูปภาพ
                        TextButton(
                          onPressed: () {
                            selectImage(driver); // อัปโหลดรูปภาพใหม่
                          },
                          child: Text('แก้ไขรูปภาพ'),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            saveDriver(driver); // บันทึกการแก้ไขข้อมูล
                          },
                          child: Text('บันทึก'),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            showDeleteConfirmationDialog(
                                driver['number_id']); // เรียกป็อปอัพยืนยันการลบ
                          },
                          child: Text('ลบ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // สีปุ่มลบเป็นสีแดง
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            showAddDriverDialog, // เมื่อกดปุ่ม "+" จะแสดงป็อบอัพเพิ่มคนขับรถใหม่
        child: Icon(Icons.add),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}
