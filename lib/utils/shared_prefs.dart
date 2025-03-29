import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences adalah penyimpanan lokal di perangkat yang bersifat persisten, sehingga data tetap ada meskipun aplikasi ditutup.

class SharedPrefs {
  // _prefs adalah variabel privat yang menyimpan instance SharedPreferences.
  static SharedPreferences? _prefs;

  /// Inisialisasi SharedPreferences (WAJIB dipanggil di main.dart)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Cek apakah SharedPreferences sudah diinisialisasi
  static bool _isInitialized() {
    if (_prefs == null) {
      print(
        "⚠️ SharedPreferences belum diinisialisasi. Pastikan memanggil init() di main.dart!",
      );
      return false;
    }
    return true;
  }

  /// Simpan User ID
  static Future<void> saveUserId(String userId) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("user_id", userId);
    print("✅ User ID disimpan: $userId");
  }

  /// Ambil User ID
  static String? getUserId() {
    if (!_isInitialized()) return null;
    return _prefs!.getString("user_id");
  }

  /// Simpan Username
  static Future<void> saveUsername(String username) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("username", username);
  }

  /// Ambil Username
  static String? getUsername() {
    if (!_isInitialized()) return null;
    return _prefs!.getString("username");
  }

  /// Simpan Saldo
  static Future<void> saveSaldo(double saldo) async {
    if (!_isInitialized()) return;
    await _prefs!.setDouble("saldo", saldo);
    print("✅ Saldo disimpan: $saldo");
  }

  /// Ambil Saldo
  static double getSaldo() {
    if (!_isInitialized()) return 0.0;
    return _prefs!.getDouble("saldo") ?? 0.0;
  }

  /// Simpan Poin
  static Future<void> savePoin(int poin) async {
    if (!_isInitialized()) return;
    await _prefs!.setInt("poin", poin);
    print("✅ Poin disimpan: $poin");
  }

  /// Ambil Poin
  static int getPoin() {
    if (!_isInitialized()) return 0;
    return _prefs!.getInt("poin") ?? 0;
  }

  /// Simpan Profil Pengguna (sebagai JSON)
  static Future<void> saveUserProfile(Map<String, dynamic> userProfile) async {
    if (!_isInitialized()) return;
    String jsonString = jsonEncode(userProfile);
    await _prefs!.setString("user_profile", jsonString);
    print("✅ Profil pengguna disimpan.");
  }

  /// Ambil Profil Pengguna
  static Map<String, dynamic>? getUserProfile() {
    if (!_isInitialized()) return null;
    String? jsonString = _prefs!.getString("user_profile");
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  /// Simpan Saldo sebagai String
  static Future<void> saveUserBalance(String? balance) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("user_balance", balance ?? "0");
  }

  /// Ambil Saldo sebagai String
  static String getUserBalance() {
    if (!_isInitialized()) return "0";
    return _prefs!.getString("user_balance") ?? "0";
  }

  /// Simpan Poin sebagai String
  static Future<void> saveUserPoints(String? points) async {
    if (!_isInitialized()) return;
    await _prefs!.setString("user_points", points ?? "0");
  }

  /// Ambil Poin sebagai String
  static String getUserPoints() {
    if (!_isInitialized()) return "0";
    return _prefs!.getString("user_points") ?? "0";
  }

  /// Simpan Semua Data User
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

  /// Hapus Semua Data User
  static Future<void> clearUserData() async {
    if (!_isInitialized()) return;
    await _prefs!.clear();
    print("🗑 Semua data user dihapus dari SharedPreferences");
  }
}
