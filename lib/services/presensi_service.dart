// ==========================
// presensi_service.dart
// ==========================
import 'dart:convert';
import 'package:http/http.dart' as http;

class PresensiService {
  final String baseUrl = "http://10.10.77.132/skaduta_api";

  Future<Map<String, dynamic>> submitPresensi(
    String userId,
    double lat,
    double lng,
    String jenis,
    String keterangan,
    String selfiePath,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/presensi.php"),
    );

    request.fields['user_id'] = userId;
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.fields['jenis'] = jenis; // masuk, pulang, izin
    request.fields['keterangan'] = keterangan;
    request.files.add(await http.MultipartFile.fromPath('selfie', selfiePath));

    var response = await request.send();
    var result = await response.stream.bytesToString();
    return jsonDecode(result);
  }
}
