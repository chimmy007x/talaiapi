import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'ngrokhttp.dart';

class BuildingMap extends StatefulWidget {
  const BuildingMap({super.key});

  @override
  _BuildingMapState createState() => _BuildingMapState();
}

class _BuildingMapState extends State<BuildingMap> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {}; // สำหรับแสดงทุกตำแหน่ง
  Set<Marker> _driverMarkers = {}; // สำหรับแสดงตำแหน่งคนขับรถ
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _customIcon;

  final LatLng _center = const LatLng(17.2963234, 104.114407);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchBuildingLocations();
    _fetchPolylines();

    // โหลดไอคอนที่ปรับขนาดแล้ว
    _loadCustomIcon();

    // ตั้งค่าให้รีเฟรชเฉพาะตำแหน่งคนขับรถทุกๆ 2 วินาที
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _fetchDriverLocations();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _setMapStyle();
  }

  Future<void> _setMapStyle() async {
    String style = '''
    [
      {
        "featureType": "poi",
        "stylers": [
          { "visibility": "on" }
        ]
      },
      {
         "featureType": "road.highway",
         "elementType": "geometry",
        "stylers": [
          // { "color": "#ff0" },
          // { "weight": 2.0 }
        ]
      }
    ]
    ''';
    mapController.setMapStyle(style);
  }

  // ฟังก์ชันสำหรับโหลดไอคอนที่ปรับขนาดเอง
  Future<void> _loadCustomIcon() async {
    final Uint8List markerIcon =
        await _resizeImage('assets/image/bus.png', 100);
    setState(() {
      _customIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  // ฟังก์ชันสำหรับปรับขนาดรูปภาพ
  Future<Uint8List> _resizeImage(String imagePath, int targetWidth) async {
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();

    final ui.Codec codec =
        await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
        await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ฟังก์ชันสำหรับดึงตำแหน่งอาคาร
  Future<void> _fetchBuildingLocations() async {
    try {
      final response = await http.get(Uri.parse(NgrokHttp.getUrl('data_talaicsc/api/buildings.php')));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List buildings = data['buildings'];
          setState(() {
            _markers.addAll(buildings.map((building) {
              final LatLng position = _parseLatLng(building['location']);
              return Marker(
                markerId: MarkerId(building['building_id'].toString()),
                position: position,
                infoWindow: InfoWindow(
                  title: building['bname'],
                  snippet:
                      'Lat: ${position.latitude}, Lng: ${position.longitude}',
                ),
                onTap: () {
                  _showBuildingInfo(
                      building); // เมื่อกดที่มาร์กเกอร์จะแสดงข้อมูลเพิ่มเติม
                },
              );
            }).toSet());
          });
        }
      } else {
        print('Failed to load building locations');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // ฟังก์ชันสำหรับแสดงข้อมูลอาคารใน Bottom Sheet
  void _showBuildingInfo(Map building) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView( // เพิ่ม SingleChildScrollView ให้เลื่อนดูได้
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                building['bname'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              // Text('Building ID: ${building['building_id']}'),
              // SizedBox(height: 10),
              // Text('Location: ${building['location']}'),
              SizedBox(height: 10),
              // ตรวจสอบข้อมูล Base64 ก่อนการแปลงและแสดงผลรูปภาพ
              if (building['Bphoto'] != null) ...[
                Container(
                  height: 300,
                  child: Image.memory(
                    base64Decode(building['Bphoto'].split(',').last),
                    fit: BoxFit.contain,
                  ),
                ),
              ] else ...[
                Text('No photo available'),
              ]
            ],
          ),
        ),
      );
    },
  );
}


 
  // ฟังก์ชันสำหรับตรวจสอบและแสดงรูปภาพ
Widget _showImage(String base64Image) {
  try {
    // ตรวจสอบว่ามีข้อมูล Base64 และมีความยาวเพียงพอหรือไม่
    if (base64Image.isEmpty || base64Image.length < 50) {
      print('Invalid Base64 image data: $base64Image');
      return Text('Invalid image data');
    }

    // ตรวจสอบว่ามี data URI หรือไม่
    if (base64Image.contains('data:image')) {
      print('Base64 contains Data URI');
      // แยกข้อมูล Base64 จาก Data URI
      base64Image = base64Image.split(',').last;
    }

    // พิมพ์ข้อมูล Base64 ส่วนแรกออกมาเพื่อดูว่าข้อมูลมีปัญหาหรือไม่
    print('Base64 Image (first 100 chars): ${base64Image.substring(0, 100)}');

    // แปลง Base64 เป็น Uint8List สำหรับแสดงรูปภาพ
    Uint8List imageData = base64Decode(base64Image);

    // แสดงรูปภาพ
    return Container(
      height: 150, // กำหนดขนาดให้เล็กลง
      child: Image.memory(
        imageData,
        fit: BoxFit.contain,
      ),
    );
  } catch (e) {
    // พิมพ์ข้อผิดพลาดที่เกิดขึ้น
    print('Error decoding image: $e');
    return Text('Failed to load image');
  }
}


  // ฟังก์ชันสำหรับดึงตำแหน่งคนขับรถ (รีเฟรชทุกๆ 2 วินาที)
  Future<void> _fetchDriverLocations() async {
  try {
    final response = await http.get(Uri.parse(NgrokHttp.getUrl('data_talaicsc/api/getposition_drivers.php')));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        final List drivers = data['drivers'];

        setState(() {
          _driverMarkers.clear();
          drivers.forEach((driver) {
            if (driver['position'] != null) {
              final LatLng position = _parseLngLat(driver['position']);
              _driverMarkers.add(
                Marker(
                  markerId: MarkerId(driver['number_id'].toString()),
                  position: position,
                  icon: _customIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                  infoWindow: InfoWindow(
                    title: '${driver['fname']} ${driver['lname']}',
                    snippet: 'Bus ID: ${driver['bus_id']}',
                  ),
                  onTap: () {
                    // _showDriverInfo(driver); // เมื่อกดที่มาร์กเกอร์คนขับจะแสดงข้อมูลเพิ่มเติม
                  },
                ),
              );
            }
          });
        });
      }
    } else {
      print('Failed to load driver locations');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// ฟังก์ชันสำหรับแสดงข้อมูลคนขับใน Bottom Sheet
// void _showDriverInfo(Map driver) {
//   showModalBottomSheet(
//     context: context,
//     builder: (BuildContext context) {
//       return Container(
//         padding: EdgeInsets.all(16.0),
//         height: 250,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               '${driver['fname']} ${driver['lname']}',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             Text('Bus ID: ${driver['bus_id']}'),
//             SizedBox(height: 10),
//             Text('Driver ID: ${driver['number_id']}'),
//             SizedBox(height: 10),
//             Text('Position: ${driver['position']}'),
//             SizedBox(height: 10),
//           ],
//         ),
//       );
//     },
//   );
// }


  // ฟังก์ชันสำหรับดึงข้อมูลเส้นทาง (Polyline)
  Future<void> _fetchPolylines() async {
    List<LatLng> polylinePoints = [
      LatLng(17.29646574581259, 104.11384165617754),
      LatLng(17.286166472068803, 104.10526099264818),
      LatLng(17.285160113773625, 104.10656464996325),
      LatLng(17.28906778568359, 104.10983808183268),
      LatLng(17.290097327213882, 104.10853454636624),
      LatLng(17.28790679605291, 104.11136840195036),
      LatLng(17.287927284341897, 104.1113469442789),
      LatLng(17.28755849479102, 104.11207650510816),
      LatLng(17.286882378695623, 104.11387894950988),
      LatLng(17.28473108364701, 104.11679719292484),
      LatLng(17.28456717442569, 104.11688302361061),
      LatLng(17.284239355545328, 104.11741946539685),
      LatLng(17.283604204797857, 104.11832068760373),
      LatLng(17.283647770957955, 104.11827478685242),
      LatLng(17.28346078332254, 104.11847089135152),
      LatLng(17.275305132216058, 104.13224988730042),
      LatLng(17.274465052894943, 104.13330391650781),
      LatLng(17.27430113453758, 104.13344339137223),
      LatLng(17.273973297385353, 104.13369015459389),
      LatLng(17.273573745067402, 104.13393691781555),
      LatLng(17.272528757966832, 104.13445190194071),
      LatLng(17.27231416345476, 104.1344865457032),
      LatLng(17.272058037967494, 104.1345294610461),
      LatLng(17.27175068691286, 104.13456164755327),
      LatLng(17.271217943848846, 104.13458310521665),
      LatLng(17.270787650267206, 104.13455091870946),
      LatLng(17.264507298530532, 104.13415395177022),
      LatLng(17.264527789422036, 104.13428269779891),
      LatLng(17.271381864944694, 104.13470112239784),
      LatLng(17.27171995175815, 104.13470112239784),
      LatLng(17.272099018048323, 104.13466893589067),
      LatLng(17.27277518841849, 104.13449727451908),
      LatLng(17.27279567839083, 104.13444363034046),
      LatLng(17.273482091176398, 104.13415395175949),
      LatLng(17.274055807339504, 104.13381062901631),
      LatLng(17.27448609330535, 104.13347803509677),
      LatLng(17.274762705171117, 104.13323127187512),
      LatLng(17.274988092310252, 104.13289867796765),
      LatLng(17.275367151896518, 104.1324051514962),
      LatLng(17.28331697837699, 104.11901556411367),
      LatLng(17.28356284382618, 104.11874734321253),
      LatLng(17.28372675394151, 104.11839329163361),
      LatLng(17.284341415587885, 104.11758862893483),
      LatLng(17.284474592004607, 104.11751352708477),
      LatLng(17.284751188883067, 104.11713801782268),
      LatLng(17.284781921842473, 104.11699854295826),
      LatLng(17.286584913180068, 104.11460601252192),
      LatLng(17.28868496605144, 104.11631189739235),
      LatLng(17.288859115699115, 104.11636554157097),
      LatLng(17.289002532932297, 104.11634408389952),
      LatLng(17.291184509966733, 104.11355458658231),
      LatLng(17.29454489819519, 104.1163203943194),
      LatLng(17.29396776235932, 104.11710529435597),
      LatLng(17.294381232999918, 104.11741203691143),
      LatLng(17.294958367539024, 104.11770073577544),
      LatLng(17.295389063776806, 104.11784508520745),
      LatLng(17.295673322762823, 104.11793530362196),
      LatLng(17.29569916446512, 104.1181788932885),
      LatLng(17.295897284062097, 104.1183051990415),
      LatLng(17.29569916446512, 104.1181788932885),
      LatLng(17.295647481056907, 104.11791725994297),
      LatLng(17.295182329729798, 104.11775486683197),
      LatLng(17.29466549354282, 104.11756540820245),
      LatLng(17.293950534413327, 104.11712333805534),
      LatLng(17.2951306461623, 104.11558962530388),
      LatLng(17.295811145139595, 104.11472352869916),
      LatLng(17.29602649238647, 104.11447091719315),
      LatLng(17.29648302772425, 104.11388449761601),
      LatLng(17.293104309055938, 104.11106577511917),
      LatLng(17.291191714723443, 104.11350270740498),
      LatLng(17.28993694455512, 104.11243096757018),
      LatLng(17.291873916237968, 104.11004507048287),
      LatLng(17.293104309045123, 104.11105301629664),
      LatLng(17.290180589932632, 104.10862884281859),
      LatLng(17.288316694708307, 104.11106577516303),
      LatLng(17.289924762251033, 104.11243096759539),
      LatLng(17.288316694708307, 104.11106577516303),
      LatLng(17.287841581138185, 104.11170371557391),
      LatLng(17.287707574529694, 104.1120226857684),
      LatLng(17.287110634815843, 104.11377064243415),
      LatLng(17.28657460566366, 104.11459996494533),
      // LatLng(),
      // LatLng(),
      // LatLng(),
      // LatLng(),
    ];

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('polyline_1'),
        points: polylinePoints,
        color: const Color.fromARGB(255, 48, 203, 250),
        width: 2,
      ));
    });
  }

  // ฟังก์ชันสำหรับแยกค่าละติจูดและลองจิจูด
  LatLng _parseLatLng(String location) {
    final parts =
        location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    final lat = double.parse(parts[0]);
    final lng = double.parse(parts[1]);
    return LatLng(lat, lng);
  }

  LatLng _parseLngLat(String location) {
    final parts =
        location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    final lng = double.parse(parts[0]);
    final lat = double.parse(parts[1]);
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 15.0,
      ),
      markers: _markers.union(_driverMarkers),
      polylines: _polylines,
    );
  }
}
