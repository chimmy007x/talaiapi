import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // เพิ่มการนำเข้า intl
import 'ngrokhttp.dart';

class ComplaintOfficerPage extends StatefulWidget {
  @override
  _ComplaintOfficerPageState createState() => _ComplaintOfficerPageState();
}

class _ComplaintOfficerPageState extends State<ComplaintOfficerPage> {
  List<Map<String, dynamic>> complaints = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isDataFetched = false; // ใช้ตรวจสอบว่ามีการดึงข้อมูลแล้วหรือไม่
  String selectedFilter = 'today'; // ตัวเลือกเริ่มต้นเป็น "ทั้งหมด"
  int totalComplaints = 0; // ตัวแปรเก็บจำนวนคำร้องเรียนทั้งหมดตามช่วงที่เลือก

  @override
  void initState() {
    super.initState();
    fetchComplaints(); // ดึงข้อมูลเริ่มต้น
  }

  // ฟังก์ชันดึงข้อมูลการร้องเรียนจากฐานข้อมูล
  Future<void> fetchComplaints({String? startDate, String? endDate}) async {
     String apiUrl = NgrokHttp.getUrl('data_talaicsc/api/get_complaints.php');

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

          // เพิ่มการเรียงลำดับจากวันที่ล่าสุดไปเก่าสุด
          complaints.sort((a, b) {
            DateTime dateA = DateTime.parse(a['date_time']);
            DateTime dateB = DateTime.parse(b['date_time']);
            return dateB.compareTo(dateA); // เรียงจากใหม่ไปเก่า
          });

          isDataFetched = true; // ข้อมูลถูกดึงแล้ว
          totalComplaints = complaints.length; // คำนวณจำนวนคำร้องเรียนทั้งหมด
        });
      } else {
        setState(() {
          complaints = [];
          isDataFetched = true; // ไม่มีข้อมูลแต่ดึงข้อมูลแล้ว
          totalComplaints = 0; // ไม่มีข้อมูลให้รีเซ็ต
        });
      }
    } else {
      setState(() {
        complaints = [];
        isDataFetched = true; // ไม่มีข้อมูลแต่ดึงข้อมูลแล้ว
        totalComplaints = 0; // ไม่มีข้อมูลให้รีเซ็ต
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
      String formattedStartDate =
          "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
      String formattedEndDate =
          "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";

      // ดึงข้อมูลการร้องเรียนใหม่ตามช่วงวันที่ที่เลือก
      fetchComplaints(startDate: formattedStartDate, endDate: formattedEndDate);
    }
  }

  // ฟังก์ชันแปลงรูปแบบวันที่
  String formatDate(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd-MM-yyyy')
        .format(dateTime); // แปลงเป็นรูปแบบ DD-MM-YYYY
  }

  // ฟังก์ชันกรองข้อมูลตามปุ่มกรองที่เลือก
  List<Map<String, dynamic>> _filterComplaints() {
    if (selectedFilter == 'today') {
      DateTime today = DateTime.now();
      return complaints.where((complaint) {
        DateTime complaintDate = DateTime.parse(complaint['date_time']);
        return complaintDate.year == today.year &&
            complaintDate.month == today.month &&
            complaintDate.day == today.day;
      }).toList();
    } else if (selectedFilter == 'week') {
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
      return complaints.where((complaint) {
        DateTime complaintDate = DateTime.parse(complaint['date_time']);
        return complaintDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
            complaintDate.isBefore(endOfWeek.add(Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == 'month') {
      DateTime now = DateTime.now();
      return complaints.where((complaint) {
        DateTime complaintDate = DateTime.parse(complaint['date_time']);
        return complaintDate.month == now.month && complaintDate.year == now.year;
      }).toList();
    } else {
      return complaints;
    }
  }

  // ฟังก์ชันเปลี่ยนช่วงเวลา
  void _changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      totalComplaints = _filterComplaints().length; // คำนวณจำนวนการร้องเรียนตามช่วงที่เลือก
    });
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
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: () {
        setState(() {
          // รีเซ็ตการเลือกช่วงเวลา
          startDate = null;
          endDate = null;
          fetchComplaints(); // รีเฟรชข้อมูลทั้งหมด
        });
      },
    ),
  ],
),

      body: isDataFetched
          ? Column(
              children: [
                // เพิ่มปุ่มกรองข้อมูล
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedFilter == 'today'
                              ? Colors.orange
                              : Colors.grey,
                        ),
                       onPressed: () => _changeFilter('today'),
                        child: Text('วันนี้'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedFilter == 'week'
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        onPressed: () => _changeFilter('week'),
                        child: Text('สัปดาห์'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedFilter == 'month'
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        onPressed: () => _changeFilter('month'),
                        child: Text('เดือน'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedFilter == 'all'
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        onPressed: () => _changeFilter('all'),
                        child: Text('ทั้งหมด'),
                      ),
                    ],
                  ),
                ),
                Text(
                  'จำนวนการร้องเรียนทั้งหมด: $totalComplaints',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (startDate != null && endDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ข้อมูลตั้งแต่: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          DateFormat('dd-MM-yyyy').format(startDate!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          ' ถึง ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          DateFormat('dd-MM-yyyy').format(endDate!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                complaints.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Text(
                            'ไม่มีคำร้องเรียนในวันที่เลือก',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.0),
                          itemCount: _filterComplaints().length,
                          itemBuilder: (context, index) {
                            final complaint = _filterComplaints()[index];
                            return Card(
                              color: const Color.fromARGB(255, 114, 178, 115),
                              margin: EdgeInsets.only(bottom: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: ListTile(
                                title: Text('การร้องเรียน'),
                                subtitle: Text(
                                    'วันที่: ${formatDate(complaint['date_time'])}'), // ใช้ฟังก์ชันแปลงวันที่
                                onTap: () {
                                  // เมื่อกดที่รายการจะแสดงรายละเอียดการร้องเรียน
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('รายละเอียดการร้องเรียน'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'รายละเอียด: ${complaint['complaints_data']}',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              Text(
                                                  'วันที่ส่ง: ${formatDate(complaint['date_time'])}'), // ใช้ฟังก์ชันแปลงวันที่
                                              Text(
                                                  'ผู้ร้องเรียน: ${complaint['nontri_id']}'),
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
                        ),
                      ),
              ],
            )
          : Center(
              child:
                  CircularProgressIndicator()), // แสดง Loader ขณะกำลังดึงข้อมูล
    );
  }
}
