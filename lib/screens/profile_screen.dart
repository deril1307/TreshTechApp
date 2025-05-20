import 'package:flutter/material.dart';
import 'package:tubes_mobile/services/api_service.dart';

import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/screens/login_screen.dart';
import 'package:tubes_mobile/screens/edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
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
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    String? userId = await SharedPrefs.getUserId();

    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    // Ambil data lokal dulu
    var savedProfile = await SharedPrefs.getUserProfile();
    var savedBalance = await SharedPrefs.getUserBalance();
    var savedPoints = await SharedPrefs.getUserPoints();
    bool localDataAvailable =
        // ignore: unnecessary_null_comparison
        savedProfile != null && savedBalance != null && savedPoints != null;
    if (localDataAvailable) {
      // Tampilkan data dari SharedPrefs
      if (mounted) {
        setState(() {
          username = savedProfile["full_name"] ?? "New User";
          phoneNumber = savedProfile["phone_number"] ?? "Belum diinput";
          address = savedProfile["address"] ?? "Belum diinput";
          profilePicture = savedProfile["profile_picture"];
          saldo = double.tryParse(savedBalance) ?? 0.00;
          poin = int.tryParse(savedPoints) ?? 0;
        });
      }
    }

    // Jika ada koneksi, coba ambil data terbaru dari API
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        var results = await Future.wait([
          ApiService.getUserData(userId),
          ApiService.fetchUserProfile(userId),
        ]);

        var userData = results[0];
        var userProfile = results[1];

        await SharedPrefs.saveUserProfile(userProfile);
        await SharedPrefs.saveUserBalance(userData["balance"]?.toString());
        await SharedPrefs.saveUserPoints(userData["points"]?.toString());

        if (mounted) {
          setState(() {
            username =
                (userProfile["full_name"]?.isEmpty ?? true)
                    ? "New User"
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
        print("Gagal memuat data user dari APi, Ambil Dari Lokal: $e");
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// Menampilkan konfirmasi sebelum logout
  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Konfirmasi Logout"),
            content: Text("Apakah Anda yakin ingin logout?"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Batal", style: TextStyle(color: Colors.grey[700])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop(); // Tutup dialog
                  await SharedPrefs.clearUserData();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
                },
                child: Text("Logout"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        title: Text("Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 38, 198, 38),
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
                            // Container Profil (Foto + Info)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Foto Profil
                                  _buildProfilePicture(),
                                  SizedBox(width: 16),

                                  // Nama dan Tombol Edit
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username ?? "Pengguna",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[900],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        _buildActionButton(
                                          "Edit Profil",
                                          Color(0xFF2E7D32),
                                          () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        EditProfilePage(),
                                              ),
                                            );
                                            _loadUserData();
                                          },
                                          isSmall: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20),

                            // Poin & Saldo
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _buildInfoRow(
                                      "Poin Anda",
                                      "$poin Poin",
                                      Icons.star,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    margin: EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _buildInfoRow(
                                      "Saldo",
                                      "Rp ${saldo.toStringAsFixed(2)}",
                                      Icons.attach_money,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 16),

                            // Nomor Telepon & Alamat
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _buildInfoRow(
                                      "Nomor Telepon",
                                      phoneNumber ?? "-",
                                      Icons.phone,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    margin: EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _buildInfoRow(
                                      "Alamat",
                                      address ?? "-",
                                      Icons.location_on,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            // Logout
                            _buildActionButton(
                              "Logout",
                              Colors.red,
                              _confirmLogout,
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // Tambahan opsional: ubah _buildActionButton untuk mendukung ukuran kecil
  Widget _buildActionButton(
    String label,
    Color color,
    VoidCallback onPressed, {
    bool isSmall = false,
  }) {
    return SizedBox(
      height: isSmall ? 36 : 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding:
              isSmall
                  ? EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              : AssetImage('assets/images/default_profile.png')
                  as ImageProvider,
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green[700]),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
