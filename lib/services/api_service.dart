import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000";

  static Future<List<dynamic>> getKategoriSampah() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/trash/types"));
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal mengambil data kategori sampah");
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(
    String identifier, // Bisa email atau username
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"identifier": identifier, "password": password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final url = "$baseUrl/users/$userId";
      print(" Mengakses API: $url");

      final response = await http.get(Uri.parse(url));
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception(" User tidak ditemukan.");
      } else {
        throw Exception(" Gagal mengambil data user: ${response.statusCode}");
      }
    } catch (e) {
      print(" Error: $e");
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  static Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      var response = await Dio().get("$baseUrl/get-profile/$userId");
      if (response.statusCode == 200 && response.data["success"]) {
        return response.data["data"];
      }
    } catch (e) {
      print(" Error mengambil profil: $e");
    }
    return {};
  }
}
