import 'dart:async'; // เพิ่มไลบรารีนี้สำหรับใช้ Timer
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'ngrokhttp.dart';
class Mappage extends StatefulWidget {
  const Mappage({super.key});

  @override
  _MappageState createState() => _MappageState();
}

class _MappageState extends State<Mappage> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _timer;

  final LatLng _center = const LatLng(17.2963234, 104.114407); // กำหนดตำแหน่งเริ่มต้นบนแผนที่

  @override
  void initState() {
    super.initState();
    _fetchBuildingLocations();
    _fetchPolylines();

    // ตั้ง Timer เพื่อรีเฟรชทุกๆ 5 วินาที
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      _fetchBuildingLocations(); // รีเฟรชตำแหน่งทุกๆ 5 วินาที
    });
  }

  @override
  void dispose() {
    // ยกเลิก Timer เมื่อ widget ถูกลบออก
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
          { "color": "#ff0000" },
          { "weight": 2.0 }
        ]
      }
    ''';
    mapController.setMapStyle(style);
  }

  Future<void> _fetchBuildingLocations() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/getuser_position.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data); // ตรวจสอบข้อมูลที่ดึงมา

        if (data['success']) {
          final List buildings = data['positions'];
          setState(() {
            _markers = buildings.map((building) {
              final LatLng position = _parseLocation(building['location']);
              final String buildingId = building['position_id'].toString();

              // สร้าง Marker ด้วยไอคอนตำแหน่ง
              return Marker(
                markerId: MarkerId(buildingId),
                position: position,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // ใช้ Marker สีฟ้า
                infoWindow: InfoWindow(
                  title: 'Position ID: $buildingId',
                ),
              );
            }).toSet();
          });
        } else {
          print('No positions found');
        }
      } else {
        print('Failed to load building locations');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

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
    ];

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('polyline_1'),
        points: polylinePoints,
        color: Colors.red,
        width: 2,
      ));
    });
  }

  LatLng _parseLocation(String location) {
    final parts = location.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
    final lng = double.parse(parts[0]); // ลองจิจูดมาก่อน
    final lat = double.parse(parts[1]); // ละติจูดมาตามหลัง
    return LatLng(lat, lng);
  }

  Future<void> _clearOldPositions() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2/data_talaicsc/api/delete_old_positions.php'));
      final data = jsonDecode(response.body);

      if (data['success']) {
        _fetchBuildingLocations(); // ดึงข้อมูลตำแหน่งใหม่หลังจากลบข้อมูลเก่าแล้ว
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบตำแหน่งเก่าแล้ว'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถลบตำแหน่งได้'))
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการลบตำแหน่ง'))
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 15.0,
          ),
          markers: _markers,
          polylines: _polylines,
        ),
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 - 28,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                onPressed: _clearOldPositions,
                child: Icon(Icons.clear),
                backgroundColor: Colors.red,
              ),
              SizedBox(width: 16), // ช่องว่างระหว่างปุ่ม
              // FloatingActionButton(
              //   onPressed: () {
              //     // เรียกใช้ฟังก์ชันรีเฟรช
              //     _fetchBuildingLocations();
              //     _fetchPolylines();
              //   },
              //   child: Icon(Icons.refresh),
              //   backgroundColor: Colors.blue,
              // ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
