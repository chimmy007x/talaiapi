import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import 'package:intl/intl.dart';  // เพิ่มการนำเข้า intl
import 'ngrokhttp.dart';

class RequestPage extends StatefulWidget {
  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  List<Map<String, dynamic>> requests = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isDataFetched = false;

  String selectedFilter = 'week';  // ตัวเลือกเริ่มต้นเป็นรายสัปดาห์
  int totalRequests = 0; // ตัวแปรสำหรับเก็บจำนวนการเรียกรถทั้งหมด

  @override
  void initState() {
    super.initState();
    _setInitialDateRange();  // ตั้งค่าช่วงวันที่เริ่มต้น
    fetchRequests();  // ดึงข้อมูลเริ่มต้น
  }

  // ฟังก์ชันตั้งช่วงวันที่ของสัปดาห์
  void _setInitialDateRange() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    startDate = now.subtract(Duration(days: currentWeekday - 1)); // วันจันทร์
    endDate = now.add(Duration(days: 7 - currentWeekday)); // วันอาทิตย์
  }

  // ฟังก์ชันดึงข้อมูลการเรียกรถจากฐานข้อมูล
  Future<void> fetchRequests({String? startDate, String? endDate}) async {
    String apiUrl = NgrokHttp.getUrl('data_talaicsc/api/get_requests.php');

    // ส่งช่วงวันที่ไปกับ API
    if (startDate != null && endDate != null) {
      apiUrl += '?start_date=$startDate&end_date=$endDate';
    }

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          requests = List<Map<String, dynamic>>.from(data['requests']);
          isDataFetched = true;
          _calculateTotalRequests(); // คำนวนจำนวนการเรียกรถทั้งหมดตามช่วงเวลาที่เลือก
          // จัดเรียงข้อมูลใหม่ไปเก่า
          requests.sort((a, b) {
            DateTime dateA = DateTime.parse(a['request_date']);
            DateTime dateB = DateTime.parse(b['request_date']);
            return dateB.compareTo(dateA); // ใหม่ไปเก่า
          });
        });
      } else {
        setState(() {
          requests = [];
          isDataFetched = true;
          totalRequests = 0; // ถ้าไม่มีข้อมูลให้ตั้งค่าเป็น 0
        });
      }
    } else {
      setState(() {
        requests = [];
        isDataFetched = true;
        totalRequests = 0; // ถ้าไม่มีข้อมูลให้ตั้งค่าเป็น 0
      });
      print('Server error: ${response.statusCode}');
    }
  }

  // ฟังก์ชันเปลี่ยนช่วงเวลา (สำหรับการจัดการข้อมูลใน ListView เท่านั้น)
  void _changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      _setInitialDateRange();
      fetchRequests();
    });
  }

  // ฟังก์ชันคำนวณจำนวนการเรียกรถทั้งหมดในช่วงเวลาที่เลือก
  void _calculateTotalRequests() {
    List<Map<String, dynamic>> filteredRequests = _filterRequestsByDateRange();
    totalRequests = filteredRequests.fold(0, (sum, request) {
      return sum + (request['total_requests'] as int);
    });
  }

  // ฟังก์ชันแปลงรูปแบบวันที่
  String formatDate(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd-MM-yyyy').format(dateTime); // แปลงเป็นรูปแบบ DD-MM-YYYY
  }

  // ฟังก์ชันกรองข้อมูลตามช่วงเวลาที่เลือก
  List<Map<String, dynamic>> _filterRequestsByDateRange() {
    if (selectedFilter == 'today') {
      // กรองเฉพาะข้อมูลของวันนี้
      return requests.where((request) {
        DateTime requestDate = DateTime.parse(request['request_date']);
        DateTime today = DateTime.now();
        return requestDate.year == today.year &&
               requestDate.month == today.month &&
               requestDate.day == today.day;
      }).toList();
    } else if (selectedFilter == 'week') {
      // กรองข้อมูลในช่วงสัปดาห์
      return requests.where((request) {
        DateTime requestDate = DateTime.parse(request['request_date']);
        return requestDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
               requestDate.isBefore(endDate!.add(Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == 'month') {
      // กรองข้อมูลในช่วงเดือน
      return requests.where((request) {
        DateTime requestDate = DateTime.parse(request['request_date']);
        return requestDate.month == startDate!.month &&
               requestDate.year == startDate!.year;
      }).toList();
    }
    // กรองทั้งหมด (ไม่มีข้อจำกัด)
    return requests;
  }

  // ฟังก์ชันสร้างข้อมูลสำหรับกราฟ (แสดงเฉพาะข้อมูลรายสัปดาห์)
  List<charts.Series<RequestData, String>> _createRequestData() {
    // กรองข้อมูลเฉพาะในช่วงสัปดาห์
    List<Map<String, dynamic>> filteredRequests = requests.where((request) {
      DateTime requestDate = DateTime.parse(request['request_date']);
      return requestDate.isAfter(startDate!.subtract(Duration(days: 1))) &&
             requestDate.isBefore(endDate!.add(Duration(days: 1)));
    }).toList();

    final requestData = filteredRequests
        .map((request) => RequestData(request['request_date'], request['total_requests']))
        .toList();

    return [
      charts.Series<RequestData, String>(
        id: 'Requests',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (RequestData request, _) => formatDate(request.date),  // แปลงวันที่ในกราฟ
        measureFn: (RequestData request, _) => request.total,
        data: requestData,
      )
    ];
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

      String formattedStartDate =
          "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
      String formattedEndDate =
          "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";

      fetchRequests(startDate: formattedStartDate, endDate: formattedEndDate);
    }
  }

  // ฟังก์ชันแสดงป็อปอัพสำหรับ nontri_id ที่ไม่ซ้ำกัน
  void _showNontriIdPopup(int uniqueNontriIds) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('จำนวนผู้ใช้ที่ไม่ซ้ำ'),
          content: Text('จำนวนบัญชีผู้ใช้งาน: $uniqueNontriIds คน'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text('จำนวนการกดเรียกรถ'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: selectDateRange,
          ),
        ],
      ),
      body: isDataFetched
          ? requests.isEmpty
              ? Center(
                  child: Text(
                    'ไม่มีข้อมูลการเรียกรถในช่วงวันที่เลือก',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // เพิ่มชื่อกราฟ
                      Text(
                        'กราฟข้อมูลรายสัปดาห์',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16), // ระยะห่างระหว่างชื่อกราฟและกราฟ

                      // กราฟแสดงข้อมูล (แสดงเฉพาะข้อมูลรายสัปดาห์)
                      SizedBox(
                        height: 400, // ขนาดกราฟ
                        child: charts.BarChart(
                          _createRequestData(),
                          animate: true,
                        ),
                      ),
                      SizedBox(height: 16), // ระยะห่างระหว่างกราฟและปุ่ม

                      // ปุ่มเลือกช่วงเวลา วันนี้ สัปดาห์ เดือน ใต้กราฟ (ไม่เกี่ยวกับการแสดงกราฟ)
                      Row(
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
                      SizedBox(height: 16), // เพิ่มระยะห่างระหว่างปุ่มและจำนวนการเรียกรถ

                      // แสดงจำนวนการเรียกรถทั้งหมดในช่วงเวลาที่เลือก
                      Text(
                        'จำนวนการเรียกรถทั้งหมดในช่วงเวลา: $totalRequests',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),

                      SizedBox(height: 16), // เพิ่มระยะห่างระหว่างจำนวนการเรียกรถและ ListView

                      // กรองและแสดงข้อมูลการเรียกรถใน ListView ตามช่วงเวลาที่เลือก
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filterRequestsByDateRange().length,
                          itemBuilder: (context, index) {
                            final request = _filterRequestsByDateRange()[index];
                            return ListTile(
                              title: Text(
                                  'วันที่: ${formatDate(request['request_date'])}'), // แปลงวันที่ในการแสดงผล
                              subtitle: Text(
                                  'จำนวนการเรียกรถ: ${request['total_requests']}'),
                              trailing: IconButton(
                                icon: Icon(Icons.info),
                                onPressed: () {
                                  _showNontriIdPopup(
                                      request['unique_nontri_ids']);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

// โมเดลสำหรับข้อมูลการเรียกรถ
class RequestData {
  final String date;
  final int total;

  RequestData(this.date, this.total);
}
