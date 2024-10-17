class NgrokHttp {
  // เก็บลิงค์ URL ที่คุณต้องการใช้
  static const String baseUrl = 'http://10.0.2.2';
//คำสั่ง ngrok http 80
  // Method เพื่อให้ URL พร้อมต่อการใช้งาน
  static String getUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
