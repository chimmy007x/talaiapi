import 'package:flutter/material.dart';

class OfficerPage extends StatefulWidget {
  const OfficerPage({super.key});

  @override
  State<OfficerPage> createState() => _OfficerPageState();
}

class _OfficerPageState extends State<OfficerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/image/logo.png', // ใส่ path ของโลโก้ที่คุณต้องการใช้
          ),
        ),
        title: Row(
          children: [
            const Text('Talai Officer', style: TextStyle(fontSize: 25)),
            const Spacer(),
            const Icon(Icons.directions_bus),
            const SizedBox(width: 10),
            const Text(
              'KU CSC',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildGridButton(
                        context,
                        icon: Icons.person,
                        label: 'ข้อมูลคนขับรถ',
                        onTap: () {
                          Navigator.pushNamed(context, '/edit_D'); // ไปยังหน้าข้อมูลคนขับรถ
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildGridButton(
                        context,
                        icon: Icons.report,
                        label: 'ร้องเรียน',
                        onTap: () {
                          Navigator.pushNamed(context, '/comoff'); // ไปยังหน้าร้องเรียน
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16), // เพิ่มระยะห่างระหว่างแถวปุ่ม
                Row(
                  children: [
                    Expanded(
                      child: _buildGridButton(
                        context,
                        icon: Icons.directions_car,
                        label: 'จำนวนการกดเรียกรถ',
                        onTap: () {
                          Navigator.pushNamed(context, '/raqp'); // ไปยังหน้าร้องเรียน
                        },
                      ),
                    ),
                    Expanded(child: Container()), // ใส่ปุ่มเพิ่มเติมได้ถ้าต้องการ
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutConfirmationDialog(); // แสดงป็อปอัพเมื่อกดออกจากระบบ
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

  Widget _buildGridButton(BuildContext context, {required IconData icon, required String label, required Function() onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      onPressed: onTap, // ใช้ onTap เพื่อกำหนดการทำงานของปุ่ม
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // ฟังก์ชันสำหรับแสดงป็อปอัพยืนยันการออกจากระบบ
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
                Navigator.of(context).pop(); // ปิดป็อปอัพก่อน
                Navigator.pushNamedAndRemoveUntil(
                  context, '/', (Route<dynamic> route) => false); // กลับไปยังหน้าแรกและลบหน้าอื่นๆ
              },
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }
}
