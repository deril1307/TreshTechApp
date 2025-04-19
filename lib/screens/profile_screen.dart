import 'package:flutter/material.dart';
import 'package:tubes_mobile/services/api_service.dart';

import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/screens/login_screen.dart';
import 'package:tubes_mobile/screens/edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  String? phoneNumber;
  String? address;
  double saldo = 0;
  int poin = 0;
  String? profilePicture;
  bool isLoading = true;

  @override
  @override
  void initState() {
    super.initState();
    _loadUserData(); // Mengganti _loadLocalUserData() dengan _loadUserData()
  }

  /// Load data dari SharedPreference atau API
  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    String? userId = await SharedPrefs.getUserId();

    if (userId == null) {
      print("⚠️ User ID tidak ditemukan");
      setState(() => isLoading = false);
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      // Jika online, ambil data dari API
      try {
        var results = await Future.wait([
          ApiService.getUserData(userId),
          ApiService.fetchUserProfile(userId),
        ]);

        var userData = results[0];
        var userProfile = results[1];

        // Simpan ke SharedPreferences
        await SharedPrefs.saveUserProfile(userProfile);
        await SharedPrefs.saveUserBalance(userData["balance"]?.toString());
        await SharedPrefs.saveUserPoints(userData["points"]?.toString());

        if (mounted) {
          setState(() {
            username =
                (userProfile["full_name"]?.isEmpty ?? true)
                    ? "Silahkan Input"
                    : userProfile["full_name"];
            phoneNumber =
                (userProfile["phone_number"]?.isEmpty ?? true)
                    ? "Belum diinput"
                    : userProfile["phone_number"];
            address =
                (userProfile["address"]?.isEmpty ?? true)
                    ? "Belum diinput"
                    : userProfile["address"];
            profilePicture =
                userProfile["profile_picture"]?.isEmpty ?? true
                    ? null
                    : userProfile["profile_picture"];

            saldo =
                double.tryParse(userData["balance"]?.toString() ?? "0.00") ??
                0.00;
            poin = int.tryParse(userData["points"]?.toString() ?? "0") ?? 0;
          });
        }
      } catch (e) {
        print(" Gagal memuat data user dari API: $e");
      }
    } else {
      // Jika offline, ambil dari SharedPreferences
      print(" Tidak ada koneksi, memuat dari SharedPreferences...");

      var savedProfile = await SharedPrefs.getUserProfile();
      var savedBalance = await SharedPrefs.getUserBalance();
      var savedPoints = await SharedPrefs.getUserPoints();

      if (mounted) {
        setState(() {
          username = savedProfile?["full_name"] ?? "Silahkan Input";
          phoneNumber = savedProfile?["phone_number"] ?? "Belum diinput";
          address = savedProfile?["address"] ?? "Belum diinput";
          profilePicture = savedProfile?["profile_picture"];
          saldo = double.tryParse(savedBalance) ?? 0.00;
          poin = int.tryParse(savedPoints) ?? 0;
        });
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// Logout dan kembali ke halaman login
  void _logout() async {
    await SharedPrefs.clearUserData();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text("Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadUserData,
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildProfilePicture(),
                            SizedBox(height: 16),
                            Text(
                              username ?? "Pengguna",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                            Text(
                              "Pahlawan Daur Ulang 🌱",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(height: 20),
                            _buildUserInfoCard(),
                            SizedBox(height: 20),
                            _buildActionButton(
                              "Edit Profil",
                              Color(0xFF2E7D32),
                              () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(),
                                  ),
                                );
                                _loadUserData();
                              },
                            ),
                            SizedBox(height: 20),
                            _buildActionButton("Logout", Colors.red, _logout),
                          ],
                        ),
                      ),
                    ),
          ),
          // Tambahin di sini
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white,
      backgroundImage:
          (profilePicture != null && profilePicture!.isNotEmpty)
              ? CachedNetworkImageProvider(profilePicture!)
              : null,
      child:
          (profilePicture == null || profilePicture!.isEmpty)
              ? Icon(Icons.eco, size: 50, color: Color(0xFF2E7D32))
              : null,
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow("Nomor Telepon", phoneNumber ?? "-", Icons.phone),
            Divider(),
            _buildInfoRow("Alamat", address ?? "-", Icons.location_on),
            Divider(),
            _buildInfoRow("Poin Anda", "$poin Poin", Icons.star),
            Divider(),
            _buildInfoRow(
              "Saldo",
              "Rp ${saldo.toStringAsFixed(2)}",
              Icons.attach_money,
            ),
            Divider(),
            _buildInfoRow("Level", "Eco Warrior", Icons.emoji_nature),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green[700]),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
        ),
      ],
    );
  }
}
