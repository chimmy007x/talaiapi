import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login.dart';
import 'user_page.dart';
import 'bus_page.dart';
import 'complaint_page.dart';
import 'officer_page.dart';
import 'building.dart';
import 'driver.dart';
import 'map.dart';
import 'edit_driver.dart';
import 'complaint_officer.dart';
import 'requestpage.dart';

// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talai KU CSC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/main': (context) => const MyHomePage(),
        '/login': (context) => const Login(),
        '/user': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return UserPage(
            fname: args?['fname'] ?? 'Unknown',
            lname: args?['lname'] ?? 'Unknown',
            status: args?['status'] ?? 'Unknown',
            nontriId: args?['nontri_id'] ?? 'Unknown',  
          );
        },
        '/bus': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return BusPage(driverId: args?['driver_id'] ?? 'Unknown');
        },
        '/complaint': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
            return ComplaintPage(
            nontriId: args?['nontri_id'] ?? '',  // เพิ่มการส่ง nontriId ที่นี่
            );
          },  
        '/officer': (context) => const OfficerPage(),
        '/building': (context) => const BuildingMap(),
        '/driver': (context) =>  DriverPage(),
        '/map': (context) =>  Mappage(),
         '/edit_D': (context) => EditDriverPage(),
          '/comoff': (context) => ComplaintOfficerPage(),
          '/raqp': (context) => RequestPage(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Talai KU CSC',
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Image.asset(
              'assets/image/logo.png', // ใส่ path ของโลโก้ที่คุณต้องการใช้แทนไอคอนรถบัส
              height: 60,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50),
              ),
              child: Text(
                'เมนู',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('เข้าสู่ระบบ'),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: const BuildingMap(), // แสดงแผนที่ทันทีที่เปิดหน้านี้
    );
  }
}
