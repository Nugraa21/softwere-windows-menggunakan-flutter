import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class ApiEncryption {
  static const String _key = "SkadutaPresensi2025SecureKey1234";

  static String decrypt(String encryptedBase64) {
    try {
      final key = Key.fromUtf8(_key);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final data = base64Decode(encryptedBase64);
      final iv = IV(data.sublist(0, 16));
      final encryptedData = data.sublist(16);
      final decrypted = encrypter.decrypt(Encrypted(encryptedData), iv: iv);
      print("DECRYPT BERHASIL!");
      return decrypted;
    } catch (e) {
      print("GAGAL DEKRIPSI: $e");
      rethrow;
    }
  }
}
