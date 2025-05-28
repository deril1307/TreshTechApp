import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Check if SharedPreferences is initialized
  static bool _isInitialized() {
    if (_prefs == null) {
      print(
        "SharedPreferences belum diinisialisasi. Pastikan memanggil init() di main.dart!",
      );
      return false;
    }
    return true;
  }

  // DATA PENGGUNA
  static Future<void> saveUserId(String userId) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("user_id", userId);
    print("User ID disimpan: $userId");
  }

  // mengambil id pengguna
  static String? getUserId() {
    if (!_isInitialized()) return null;
    return _prefs!.getString("user_id");
  }

  // mennyimpan id pengguna
  static Future<void> saveUsername(String username) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("username", username);
    // print("Username disimpan: $username");
  }

  // mengambil username
  static String? getUsername() {
    if (!_isInitialized()) return null;
    return _prefs!.getString("username");
  }

  // menyimpan salfo
  static Future<void> saveSaldo(double saldo) async {
    if (!_isInitialized()) return;
    await _prefs!.setDouble("saldo", saldo);
  }

  // mengambil saldo
  static double getSaldo() {
    if (!_isInitialized()) return 0.0;
    return _prefs!.getDouble("saldo") ?? 0.0;
  }

  // menyimpan poin
  static Future<void> savePoin(int poin) async {
    if (!_isInitialized()) return;
    await _prefs!.setInt("poin", poin);
  }

  // mengambil poin
  static int getPoin() {
    if (!_isInitialized()) return 0;
    return _prefs!.getInt("poin") ?? 0;
  }

  // menyimpan seluruh profile
  static Future<void> saveUserProfile(Map<String, dynamic> userProfile) async {
    if (!_isInitialized()) return;
    String jsonString = jsonEncode(userProfile);
    await _prefs!.setString("user_profile", jsonString);
  }

  // mengambil seluruh profile
  static Map<String, dynamic>? getUserProfile() {
    if (!_isInitialized()) return null;
    String? jsonString = _prefs!.getString("user_profile");
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  // menyimpan hanya gambar profile nya saja
  static Future<void> saveProfilePicture(String url) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("profile_picture", url);
  }

  // mengambil hanya gambar profile nya saja
  static String? getProfilePicture() {
    if (!_isInitialized()) return null;
    return _prefs!.getString("profile_picture");
  }

  // menyimpan uang
  static Future<void> saveUserBalance(String? balance) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("user_balance", balance ?? "0");
  }

  // mengambil uang
  static String getUserBalance() {
    if (!_isInitialized()) return "0";
    return _prefs!.getString("user_balance") ?? "0";
  }

  // menyimpan poin
  static Future<void> saveUserPoints(String? points) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("user_points", points ?? "0");
  }

  // mengambil poin
  static String getUserPoints() {
    if (!_isInitialized()) return "0";
    return _prefs!.getString("user_points") ?? "0";
  }

  static Future<void> saveUserData(
    String userId,
    String username,
    double saldo,
    int poin,
  ) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("user_id", userId);
    await _prefs!.setString("username", username);
    await _prefs!.setDouble("saldo", saldo);
    await _prefs!.setInt("poin", poin);
    print("✅ Semua data user disimpan.");
  }

  static Future<void> clearUserData() async {
    if (!_isInitialized()) return;
    await _prefs!.remove("user_id");
    await _prefs!.remove("username");
    await _prefs!.remove("saldo");
    await _prefs!.remove("poin");
    await _prefs!.remove("user_profile");
    await _prefs!.remove("profile_picture");
    await _prefs!.remove("user_balance");
    await _prefs!.remove("user_points");
    print("✅ Data user dihapus, riwayat tetap ada.");
  }

  // Riwayat Notifikasi
  static const _keyRiwayat = 'riwayat_data';

  // Menambahkan riwayat
  static Future<void> tambahRiwayat(Map<String, String> item) async {
    if (!_isInitialized()) return;
    final List<String> existingData = _prefs!.getStringList(_keyRiwayat) ?? [];
    existingData.insert(0, jsonEncode(item));
    await _prefs!.setStringList(_keyRiwayat, existingData);
    print("Riwayat baru ditambahkan.");
  }

  // Mendapatkan riwayat
  static List<Map<String, String>> getRiwayat() {
    if (!_isInitialized()) return [];
    final List<String> data = _prefs!.getStringList(_keyRiwayat) ?? [];
    return data.map((e) {
      final dynamic decoded = jsonDecode(e);
      return Map<String, String>.from(decoded as Map<String, dynamic>);
    }).toList();
  }

  // Method untuk menghapus riwayat by index
  static Future<void> hapusRiwayatByIndex(int index) async {
    if (!_isInitialized()) return;
    final List<String> existingData = _prefs!.getStringList(_keyRiwayat) ?? [];
    if (index >= 0 && index < existingData.length) {
      existingData.removeAt(index);
      await _prefs!.setStringList(_keyRiwayat, existingData);
      print("Riwayat pada index $index dihapus.");
    } else {
      print("Index tidak valid.");
    }
  }

  // Method untuk menghapus semua data W
  static Future<void> hapusSemuaRiwayat() async {
    if (!_isInitialized()) return;
    await _prefs!.remove(_keyRiwayat);
    print("🗑 Semua riwayat dihapus.");
  }
}

// utils/shared_pref.dart

class SharedPrefUtils {
  static const _kategoriKey = 'cached_categories';

  // Simpan data kategori (String berupa JSON)
  static Future<void> setKategoriSampah(String dataJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kategoriKey, dataJson);
  }

  // Ambil data kategori (String berupa JSON)
  static Future<String?> getKategoriSampah() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kategoriKey);
  }
}
