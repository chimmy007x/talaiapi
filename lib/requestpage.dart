import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;

class RequestPage extends StatefulWidget {
  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  List<Map<String, dynamic>> requests = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isDataFetched = false;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ฟังก์ชันดึงข้อมูลการเรียกรถจากฐานข้อมูล
  Future<void> fetchRequests({String? startDate, String? endDate}) async {
    String apiUrl = 'http://10.0.2.2/data_talaicsc/api/get_requests.php';

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
        });
      } else {
        setState(() {
          requests = [];
          isDataFetched = true;
        });
      }
    } else {
      setState(() {
        requests = [];
        isDataFetched = true;
      });
      print('Server error: ${response.statusCode}');
    }
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

      String formattedStartDate = "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
      String formattedEndDate = "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";

      fetchRequests(startDate: formattedStartDate, endDate: formattedEndDate);
    }
  }

  // สร้างกราฟข้อมูล
  List<charts.Series<RequestData, String>> _createRequestData() {
    final requestData = requests
        .map((request) => RequestData(request['request_date'], request['total_requests']))
        .toList();

    return [
      charts.Series<RequestData, String>(
        id: 'Requests',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (RequestData request, _) => request.date,
        measureFn: (RequestData request, _) => request.total,
        data: requestData,
      )
    ];
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
                      SizedBox(
                        height: 400, // ขนาดกราฟ
                        child: charts.BarChart(
                          _createRequestData(),
                          animate: true,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            return ListTile(
                              title: Text('วันที่: ${request['request_date']}'),
                              subtitle: Text('จำนวนการเรียกรถ: ${request['total_requests']}'),
                              trailing: IconButton(
                                icon: Icon(Icons.info),
                                onPressed: () {
                                  _showNontriIdPopup(request['unique_nontri_ids']);
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
