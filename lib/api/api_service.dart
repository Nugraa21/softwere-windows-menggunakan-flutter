import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform, SocketException;
import '../utils/encryption.dart'; // Asumsi lo punya file ini untuk ApiEncryption.decrypt

class ApiService {
  // Ganti dengan URL ngrok kamu yang aktif
  static const String baseUrl =
      "https://nonlitigious-alene-uninfinitely.ngrok-free.dev/backendapk/";

  // API Key harus sama persis dengan yang di config.php
  static const String _apiKey = 'Skaduta2025!@#SecureAPIKey1234567890';

  /// Get device ID for binding (skip for Windows desktop)
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isWindows) {
        return ''; // Skip device ID for Windows desktop
      }
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Unique device ID for Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? ''; // Unique for iOS app installs
      }
      return ''; // Fallback
    } catch (e) {
      print('Error getting device ID: $e');
      return '';
    }
  }

  /// Header umum untuk semua request
  static Future<Map<String, String>> _getHeaders({
    bool withToken = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'X-App-Key': _apiKey,
      'ngrok-skip-browser-warning': 'true', // Bypass halaman warning ngrok free
      if (withToken && token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Dekripsi aman + debug print
  static Map<String, dynamic> _safeDecrypt(http.Response response) {
    try {
      print("=== RESPONSE DEBUG ===");
      print("STATUS CODE: ${response.statusCode}");
      print("BODY LENGTH: ${response.body.length}");
      print("RAW BODY: '${response.body}'");
      print("======================");

      if (response.body.isEmpty) {
        return {"status": false, "message": "Server mengirim response kosong"};
      }

      final body = jsonDecode(response.body);
      if (body['encrypted_data'] != null) {
        final decryptedJson = ApiEncryption.decrypt(body['encrypted_data']);
        return jsonDecode(decryptedJson);
      }
      return body as Map<String, dynamic>;
    } catch (e) {
      print("GAGAL PARSE JSON: $e");
      return {"status": false, "message": "Gagal membaca respons dari server"};
    }
  }

  // ================== SAFE REQUEST WRAPPER ==================
  /// Wrapper aman untuk semua request HTTP
  /// Menangani error jaringan/offline dengan pesan ramah ke user
  static Future<Map<String, dynamic>> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final res = await request().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw SocketException('Connection timed out');
        },
      );
      // Handle status code spesifik
      if (res.statusCode == 401) {
        return {
          "status": false,
          "message": "Periksa password dan username anda.",
        };
      } else if (res.statusCode == 403) {
        return {
          "status": false,
          "message": "Akses ditolak. Periksa device ID atau hubungi admin.",
        };
      } else if (res.statusCode != 200) {
        return {
          "status": false,
          "message": "Server error (${res.statusCode}). Coba lagi nanti.",
        };
      }
      return _safeDecrypt(res);
    } on SocketException catch (_) {
      return {
        "status": false,
        "message": "Kamu sedang offline. Periksa koneksi internetmu.",
      };
    } on http.ClientException catch (_) {
      return {
        "status": false,
        "message": "Tidak dapat terhubung ke server. Pastikan kamu online.",
      };
    } catch (e) {
      print("UNEXPECTED API ERROR: $e");
      return {
        "status": false,
        "message": "Terjadi kesalahan. Coba lagi nanti.",
      };
    }
  }

  // ================== GET DATA (ENKRIPSI) ==================
  static Future<List<dynamic>> getUsers() async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.get(Uri.parse("$baseUrl/get_users.php"), headers: headers),
    );
    if (result['status'] == false) return []; // Handle offline/server errors
    return List<dynamic>.from(result['data'] ?? []);
  }

  static Future<List<dynamic>> getUserHistory(String userId) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.get(
        Uri.parse("$baseUrl/absen_history.php?user_id=$userId"),
        headers: headers,
      ),
    );
    if (result['status'] == false) return []; // Handle offline/server errors
    return List<dynamic>.from(result['data'] ?? []);
  }

  static Future<List<dynamic>> getAllPresensi() async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.get(
        Uri.parse("$baseUrl/absen_admin_list.php"),
        headers: headers,
      ),
    );
    if (result['status'] == false) return []; // Handle offline/server errors
    return List<dynamic>.from(result['data'] ?? []);
  }

  static Future<List<dynamic>> getRekap({String? month, String? year}) async {
    final headers = await _getHeaders();
    var url = "$baseUrl/presensi_rekap.php";
    if (month != null && year != null) url += "?month=$month&year=$year";
    final result = await _safeRequest(
      () => http.get(Uri.parse(url), headers: headers),
    );
    if (result['status'] == false) return []; // Handle offline/server errors
    return List<dynamic>.from(result['data'] ?? []);
  }

  // ================== LOGIN ==================
  static Future<Map<String, dynamic>> login({
    required String input,
    required String password,
  }) async {
    final deviceId = await getDeviceId();

    final headers = await _getHeaders(withToken: false);
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: headers,
        body: jsonEncode({
          "username": input,
          "password": password,
          "device_id": deviceId,
        }),
      ),
    );

    // Simpan token & user info kalau login berhasil
    if (result['status'] == true && result['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result['token']);
      await prefs.setString('user_id', result['user']['id'].toString());
      await prefs.setString('user_name', result['user']['nama_lengkap']);
      await prefs.setString('user_role', result['user']['role']);
      await prefs.setString(
        'device_id',
        deviceId,
      ); // Optional: store for future checks
    }
    return result;
  }

  // ================== LOGOUT ==================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ================== CEK LOGIN STATUS ==================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  // ================== GET USER SAAT INI ==================
  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;
    return {
      'id': prefs.getString('user_id') ?? '',
      'nama_lengkap': prefs.getString('user_name') ?? '',
      'role': prefs.getString('user_role') ?? 'user',
    };
  }

  // ================== REGISTER ==================
  static Future<Map<String, dynamic>> register({
    required String username,
    required String namaLengkap,
    required String nipNisn,
    required String password,
    required String role,
    required bool isKaryawan,
  }) async {
    final deviceId = await getDeviceId();

    final headers = await _getHeaders(withToken: false);
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/register.php"),
        headers: headers,
        body: jsonEncode({
          "username": username,
          "nama_lengkap": namaLengkap,
          "nip_nisn": nipNisn,
          "password": password,
          "role": role,
          "is_karyawan": isKaryawan,
          "device_id": deviceId,
        }),
      ),
    );
    return result;
  }

  // ================== SUBMIT PRESENSI ==================
  static Future<Map<String, dynamic>> submitPresensi({
    required String userId,
    required String jenis,
    required String keterangan,
    required String informasi,
    required String dokumenBase64,
    required String latitude,
    required String longitude,
    required String base64Image,
  }) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/absen.php"),
        headers: headers,
        body: jsonEncode({
          "userId": userId,
          "jenis": jenis,
          "keterangan": keterangan,
          "informasi": informasi,
          "dokumenBase64": dokumenBase64,
          "latitude": latitude,
          "longitude": longitude,
          "base64Image": base64Image,
        }),
      ),
    );
    return result;
  }

  // ================== APPROVE PRESENSI ==================
  static Future<Map<String, dynamic>> updatePresensiStatus({
    required String id,
    required String status,
  }) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/presensi_approve.php"),
        headers: headers,
        body: jsonEncode({
          "id": id.trim(),
          "status": status, // "Disetujui" atau "Ditolak"
        }),
      ),
    );
    return result;
  }

  // ================== DELETE USER ==================
  static Future<Map<String, dynamic>> deleteUser(String id) async {
    final headers = await _getHeaders();
    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/delete_user.php"),
        headers: headers,
        body: jsonEncode({"id": id}),
      ),
    );
    return result;
  }

  // ================== UPDATE USER ==================
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    required String username,
    required String namaLengkap,
    String? nipNisn,
    String? role,
    String? password,
  }) async {
    final headers = await _getHeaders();
    final body = {
      "id": id,
      "username": username,
      "nama_lengkap": namaLengkap,
      if (nipNisn != null && nipNisn.isNotEmpty) "nip_nisn": nipNisn,
      if (role != null) "role": role,
      if (password != null && password.isNotEmpty) "password": password,
    };

    final result = await _safeRequest(
      () => http.post(
        Uri.parse("$baseUrl/update_user.php"),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return result;
  }
}
