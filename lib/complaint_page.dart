import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ngrokhttp.dart';

class ComplaintPage extends StatefulWidget {
  final String nontriId;

  const ComplaintPage({super.key, required this.nontriId});

  @override
  _ComplaintPageState createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _descriptionController = TextEditingController();
  int _rating = 0;  // สำหรับเก็บคะแนนการให้ดาว

  Future<void> _submitComplaint() async {
    final description = _descriptionController.text;

    if (description.isEmpty || widget.nontriId.isEmpty) {
      _showPopup('Error', 'Please fill out all fields');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(NgrokHttp.getUrl('data_talaicsc/api/save_complaint.php')),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'description': description,
          'nontri_id': widget.nontriId,
          'rating': _rating,  // ส่งคะแนนการให้ดาวไปด้วย
        }),
      );

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          _showPopup('ส่งคำร้องเรียนสำเร็จ', 'เราได้ทำดารส่งคำร้องเรียนไปยังเจ้าหน้าที่แล้ว');
        } else {
          _showPopup('Error', responseData['message']);
        }
      } else {
        _showPopup('Error', 'Invalid response format: ${response.body}');
      }
    } catch (e) {
      _showPopup('Error', 'Failed to submit complaint: $e');
    }
  }

 void _showPopup(String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ปิด AlertDialog
              _descriptionController.clear(); // ล้างข้อมูลใน TextField
              setState(() {
                _rating = 0; // รีเซ็ตค่า rating
              });
            },
            child: Text('เสร็จสิ้น'),
          ),
        ],
      );
    },
  );
}


  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= _rating ? Icons.star : Icons.star_border,
        color: Colors.green,
      ),
      onPressed: () {
        setState(() {
          _rating = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:const Color(0xFF4CAF50),
        title: Text('ร้องเรียน'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'ใส่ข้อมูลที่ต้องการร้องเรียน...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'ยืนยันการส่งข้อมูลร้องเรียน',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
