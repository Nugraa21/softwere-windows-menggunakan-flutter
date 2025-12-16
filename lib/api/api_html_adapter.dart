import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://ludang.wuaze.com/";

  /// ===============================
  /// Helper: Parse JSON dari HTML atau JSON biasa
  /// ===============================
  static dynamic parseHtmlJsonSafe(String body) {
    try {
      // Coba ambil JSON object { ... }
      final start = body.indexOf('{');
      final end = body.lastIndexOf('}');
      if (start != -1 && end != -1) {
        final jsonStr = body.substring(start, end + 1);
        return jsonDecode(jsonStr);
      }

      // Coba ambil JSON array [ ... ]
      final arrStart = body.indexOf('[');
      final arrEnd = body.lastIndexOf(']');
      if (arrStart != -1 && arrEnd != -1) {
        final jsonStr = body.substring(arrStart, arrEnd + 1);
        return jsonDecode(jsonStr);
      }

      // Jika tetap gagal
      throw Exception('Tidak ada JSON valid ditemukan');
    } catch (e) {
      print('DEBUG HTML JSON PARSE ERROR: $e');
      print('DEBUG BODY: $body');
      return {
        "status": "error",
        "message": "Response bukan JSON valid",
        "raw": body,
      };
    }
  }

  /// ===============================
  /// LOGIN
  /// ===============================
  static Future<Map<String, dynamic>> login({
    required String input,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {"input": input, "password": password},
    );
    print('DEBUG LOGIN BODY: ${res.body}');
    return parseHtmlJsonSafe(res.body);
  }

  /// ===============================
  /// REGISTER
  /// ===============================
  static Future<Map<String, dynamic>> register({
    required String username,
    required String namaLengkap,
    required String nipNisn,
    required String password,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        "username": username,
        "nama_lengkap": namaLengkap,
        "nip_nisn": nipNisn,
        "password": password,
        "role": role,
      },
    );
    print('DEBUG REGISTER BODY: ${res.body}');
    return parseHtmlJsonSafe(res.body);
  }

  /// ===============================
  /// GET ALL USERS
  /// ===============================
  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/get_users.php"));
    print('DEBUG GET USERS BODY: ${res.body}');
    final data = parseHtmlJsonSafe(res.body);
    if (data["status"] == "success" && data["data"] != null) {
      return data["data"] as List<dynamic>;
    }
    return [];
  }

  /// ===============================
  /// DELETE USER
  /// ===============================
  static Future<Map<String, dynamic>> deleteUser(String id) async {
    final res = await http.post(
      Uri.parse("$baseUrl/delete_user.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {"id": id},
    );
    print('DEBUG DELETE BODY: ${res.body}');
    return parseHtmlJsonSafe(res.body);
  }

  /// ===============================
  /// UPDATE USER
  /// ===============================
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String username,
    required String namaLengkap,
    String? password,
  }) async {
    final body = {"id": id, "username": username, "nama_lengkap": namaLengkap};
    if (password != null && password.isNotEmpty) {
      body["password"] = password;
    }
    final res = await http.post(
      Uri.parse("$baseUrl/update_user.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    print('DEBUG UPDATE USER BODY: ${res.body}');
    return parseHtmlJsonSafe(res.body);
  }

  /// ===============================
  /// UPDATE PASSWORD TERPISAH
  /// ===============================
  static Future<Map<String, dynamic>> updateUserPassword({
    required String id,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/update_password.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {"id": id, "password": newPassword},
    );
    print('DEBUG UPDATE PASSWORD BODY: ${res.body}');
    return parseHtmlJsonSafe(res.body);
  }

  /// ===============================
  /// PRESENSI SUBMIT
  /// ===============================
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String jenis,
    required String keterangan,
    required String latitude,
    required String longitude,
    required String base64Image,
  }) async {
    final body = {
      "userId": userId,
      "jenis": jenis,
      "keterangan": keterangan,
      "latitude": latitude,
      "longitude": longitude,
      "base64Image": base64Image,
    };
    print('DEBUG PRESENSI REQUEST: ${jsonEncode(body)}');
    final res = await http.post(
      Uri.parse("$baseUrl/absen.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    print('DEBUG PRESENSI BODY: ${res.body}');
    return parseHtmlJsonSafe(res.body);
  }

  /// ===============================
  /// GET USER HISTORY
  /// ===============================
  static Future<List<dynamic>> getUserHistory(String userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/absen_history.php?user_id=$userId"),
    );
    print('DEBUG HISTORY BODY: ${res.body}');
    final data = parseHtmlJsonSafe(res.body);
    if (data["status"] == true && data["data"] != null) {
      return data["data"] as List<dynamic>;
    }
    return [];
  }

  /// ===============================
  /// GET ALL PRESENSI
  /// ===============================
  static Future<List<dynamic>> getAllPresensi() async {
    final res = await http.get(Uri.parse("$baseUrl/presensi_rekap.php"));
    print('DEBUG ALL PRESENSI BODY: ${res.body}');
    final data = parseHtmlJsonSafe(res.body);
    if (data["status"] == "success" && data["data"] != null) {
      return data["data"] as List<dynamic>;
    }
    return [];
  }

  /// ===============================
  /// UPDATE PRESENSI STATUS
  /// ===============================
  static Future<Map<String, dynamic>> updatePresensiStatus({
    required String id,
    required String status,
  }) async {
    final body = {"id": id, "status": status};
    print('DEBUG UPDATE PRESENSI REQUEST: ${jsonEncode(body)}');
    final res = await http.post(
      Uri.parse("$baseUrl/presensi_approve.php"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    print('DEBUG UPDATE PRESENSI BODY: ${res.body}');
    return parseHtmlJsonSafe(res.body);
  }
}
