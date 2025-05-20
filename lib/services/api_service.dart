import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
// ignore: unused_import
import 'package:tubes_mobile/utils/shared_prefs.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000";

  static Future<List<dynamic>> getKategoriSampah() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/trash/types"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal mengambil data kategori sampah");
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> setorSampah(
    int userId,
    int kategoriId,
    int beratGram,
  ) async {
    final url = Uri.parse('$baseUrl/setor-sampah');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'waste_id': kategoriId,
        'weight': beratGram,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Error: ${response.statusCode}');
      print('Response Body: ${response.body}');
      throw Exception('Gagal setor sampah');
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

  // Membuat fungsi untuk update untuk terhubung ke flask python
  static Future<Map<String, dynamic>> tarikSaldo({
    required String userId,
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/update_saldo');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "amount": amount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal tarik saldo: ${response.body}");
    }
  }

  // membuat leaderboaard
  // GET data leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await http.get(Uri.parse('$baseUrl/leaderboard'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Gagal mengambil data leaderboard.");
    }
  }
}
