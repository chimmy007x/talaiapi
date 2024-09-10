import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ComplaintOfficerPage extends StatefulWidget {
  @override
  _ComplaintOfficerPageState createState() => _ComplaintOfficerPageState();
}

class _ComplaintOfficerPageState extends State<ComplaintOfficerPage> {
  List<Map<String, dynamic>> complaints = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isDataFetched = false; // ใช้ตรวจสอบว่ามีการดึงข้อมูลแล้วหรือไม่

  @override
  void initState() {
    super.initState();
    fetchComplaints(); // ดึงข้อมูลเริ่มต้น
  }

  // ฟังก์ชันดึงข้อมูลการร้องเรียนจากฐานข้อมูล
  Future<void> fetchComplaints({String? startDate, String? endDate}) async {
    String apiUrl = 'http://10.0.2.2/data_talaicsc/api/get_complaints.php';

    // เพิ่มช่วงวันที่ใน URL หากมีการเลือกวันที่
    if (startDate != null && endDate != null) {
      apiUrl += '?start_date=$startDate&end_date=$endDate';
    }

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          complaints = List<Map<String, dynamic>>.from(data['complaints']);
          isDataFetched = true; // ข้อมูลถูกดึงแล้ว
        });
      } else {
        setState(() {
          complaints = [];
          isDataFetched = true; // ไม่มีข้อมูลแต่ดึงข้อมูลแล้ว
        });
      }
    } else {
      setState(() {
        complaints = [];
        isDataFetched = true; // ไม่มีข้อมูลแต่ดึงข้อมูลแล้ว
      });
      print('Server error: ${response.statusCode}');
    }
  }

  // ฟังก์ชันแสดงป็อปอัพข้อมูล nontri_id
  void showNontriIdPopup(String nontriId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ข้อมูลผู้ส่ง'),
          content: Text('Nontri ID: $nontriId'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันเลือกช่วงวันที่
  Future<void> selectDateRange() async {
    final pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDateRange != null) {
      setState(() {
        startDate = pickedDateRange.start;
        endDate = pickedDateRange.end;
      });

      // แปลงวันที่เป็นรูปแบบที่เหมาะสม เช่น 'YYYY-MM-DD'
      String formattedStartDate = "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
      String formattedEndDate = "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";

      // ดึงข้อมูลการร้องเรียนใหม่ตามช่วงวันที่ที่เลือก
      fetchComplaints(startDate: formattedStartDate, endDate: formattedEndDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text('ข้อมูลการร้องเรียน'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: selectDateRange, // เรียกฟังก์ชันเลือกช่วงวันที่
          ),
        ],
      ),
      body: isDataFetched
          ? complaints.isEmpty
              ? Center(
                  child: Text(
                    'ไม่มีคำร้องเรียนในช่วงวันที่เลือก',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    return Card(
                      color: const Color.fromARGB(255, 114, 178, 115),
                      margin: EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text('รหัสการร้องเรียน: ${complaint['complaint_id']}'),
                        subtitle: Text('วันที่: ${complaint['date_time']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.info),
                          onPressed: () {
                            showNontriIdPopup(complaint['nontri_id']);
                          },
                        ),
                        onTap: () {
                          // เมื่อกดที่รายการจะแสดงรายละเอียดการร้องเรียน
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('รายละเอียดการร้องเรียน'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('รหัสการร้องเรียน: ${complaint['complaint_id']}'),
                                      Text('รายละเอียด: ${complaint['complaints_data']}'),
                                      Text('วันที่ส่ง: ${complaint['date_time']}'),
                                      Text('ผู้ร้องเรียน: ${complaint['nontri_id']}'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('ปิด'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                )
          : Center(child: CircularProgressIndicator()), // แสดง Loader ขณะกำลังดึงข้อมูล
    );
  }
}
