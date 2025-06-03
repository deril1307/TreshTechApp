import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
// ignore: unused_import
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'dart:async';
// ignore: unused_import
import 'package:flutter/foundation.dart'; // untuk kReleaseMode

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000";
  // static const String baseUrl = "https://e374-114-10-145-44.ngrok-free.app";

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
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse('$baseUrl/setor-sampah');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'waste_id': kategoriId,
        'weight': beratGram,
        'latitude': latitude, // Kirim latitude
        'longitude': longitude, // Kirim longitude
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Error setorSampah API: ${response.statusCode}');
      print('Response Body setorSampah: ${response.body}');
      // Coba parse error message dari backend jika ada
      try {
        final errorData = json.decode(response.body);
        if (errorData is Map<String, dynamic> &&
            errorData.containsKey('error')) {
          throw Exception('Gagal setor sampah: ${errorData['error']}');
        }
      } catch (e) {
        // Gagal parse atau format tidak sesuai, fallback ke pesan umum
      }
      throw Exception('Gagal setor sampah (Status: ${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String fullName,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "full_name": fullName,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(
    String identifier,
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

  // reset password user
  static Future<Map<String, dynamic>> requestResetCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/request-reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "token": token,
        "new_password": newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> _handleResponse(
    http.Response response,
    String operation,
  ) async {
    print(
      'ApiService ($operation): Status ${response.statusCode}, Body: ${response.body}',
    );
    Map<String, dynamic>? responseBody;
    try {
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(response.body);
      }
    } catch (e) {
      print(
        'ApiService ($operation): Failed to decode JSON response body: ${response.body}',
      );
      throw Exception(
        'Gagal memproses respons server (Status: ${response.statusCode})',
      );
    }

    if (response.statusCode == 200) {
      if (responseBody == null && operation.contains("get")) {
        // Untuk GET yang mungkin mengembalikan nilai non-map
        throw Exception('Data tidak valid dari server untuk $operation.');
      }
      return responseBody ??
          {}; // Kembalikan map kosong jika body kosong tapi status 200 (jarang terjadi untuk API kita)
    } else if (response.statusCode == 404) {
      throw Exception(
        'Sumber daya tidak ditemukan di server untuk $operation.',
      );
    } else {
      throw Exception(
        'Gagal $operation: ${responseBody?['error'] ?? response.reasonPhrase} (Status: ${response.statusCode})',
      );
    }
  }

  static Future<T> _handleRequest<T>(
    Future<http.Response> requestFuture,
    String operation,
    T Function(dynamic data) parser,
  ) async {
    try {
      final response = await requestFuture.timeout(
        const Duration(seconds: 10),
      ); // Default timeout 10 detik
      final dynamic decodedData = await _handleResponse(response, operation);
      return parser(decodedData);
    } on TimeoutException catch (_) {
      print('ApiService ($operation): Timeout');
      throw Exception(
        'Waktu tunggu koneksi habis untuk $operation. Periksa koneksi Anda.',
      );
    } catch (e) {
      print('ApiService ($operation): Exception: $e');
      if (e is Exception &&
          (e.toString().contains('SocketException') ||
              e.toString().contains('Network is unreachable'))) {
        throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet atau alamat server.',
        );
      }
      rethrow; // Lempar kembali exception yang sudah diproses atau exception asli
    }
  }

  /// Fungsi untuk mendapatkan poin pengguna saat ini dari server.
  static Future<int> getUserPoints(String userId) async {
    final url = Uri.parse('$baseUrl/user/$userId/points');
    print('ApiService: Calling GET $url');
    return _handleRequest(
      http.get(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ),
      'mengambil poin pengguna',
      (data) {
        if (data != null && data['points'] != null) {
          return data['points'] as int;
        }
        throw Exception('Format data poin tidak valid dari server.');
      },
    );
  }

  /// Fungsi untuk mendapatkan saldo pengguna saat ini dari server.
  static Future<double> getUserBalance(String userId) async {
    final url = Uri.parse('$baseUrl/user/$userId/balance');
    print('ApiService: Calling GET $url');
    return _handleRequest(
      http.get(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      ),
      'mengambil saldo pengguna',
      (data) {
        if (data != null && data['balance'] != null) {
          return (data['balance'] as num).toDouble();
        }
        throw Exception('Format data saldo tidak valid dari server.');
      },
    );
  }

  /// Fungsi untuk melakukan penukaran poin melalui API.
  static Future<Map<String, dynamic>> tukarPoinRemote(
    String userId,
    int poinDitukar,
    int nilaiSaldoDidapat,
  ) async {
    final url = Uri.parse('$baseUrl/tukar-poin');
    print(
      'ApiService: Calling POST $url with body: {user_id: $userId, poin_ditukar: $poinDitukar, nilai_saldo_didapat: $nilaiSaldoDidapat}',
    );
    return _handleRequest(
      http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'user_id': userId,
              'poin_ditukar': poinDitukar,
              'nilai_saldo_didapat': nilaiSaldoDidapat,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          ), // Timeout khusus untuk operasi POST ini
      'melakukan penukaran poin',
      (data) =>
          data as Map<String, dynamic>, // Server diharapkan mengembalikan Map
    );
  }
}
