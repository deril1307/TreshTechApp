// ignore_for_file: unused_import, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/screens/login_screen.dart';
import 'package:tubes_mobile/screens/edit_profile_screen.dart'; // Pastikan EditProfilePage ada di sini
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

  final Color appBarColor = const Color.fromARGB(255, 38, 198, 38);
  final Color primaryAccentColor = const Color.fromARGB(255, 27, 154, 27);
  final Color scaffoldBgColor = const Color(0xFFF0F4F8);
  final Color cardColor = Colors.white;
  final Color titleTextColor = Colors.green.shade900;
  final Color bodyTextColor = Colors.black.withOpacity(0.75);
  final Color secondaryTextColor = Colors.grey.shade600;
  final Color placeholderColor = Colors.grey.shade400;
  final Color cardShadowColor = Colors.black.withOpacity(
    0.05,
  ); // const Color.fromARGB(13, 0, 0, 0)

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    String? userId = await SharedPrefs.getUserId();

    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    var savedProfile = await SharedPrefs.getUserProfile();
    var savedBalance = await SharedPrefs.getUserBalance();
    var savedPoints = await SharedPrefs.getUserPoints();
    bool localDataAvailable =
        savedProfile != null && savedBalance != null && savedPoints != null;

    if (localDataAvailable) {
      if (mounted) {
        setState(() {
          username = savedProfile["full_name"] ?? "Pengguna Baru";
          phoneNumber = savedProfile["phone_number"] ?? "Belum diinput";
          address = savedProfile["address"] ?? "Belum diinput";
          profilePicture = savedProfile["profile_picture"];
          saldo = double.tryParse(savedBalance.toString()) ?? 0.00;
          poin = int.tryParse(savedPoints.toString()) ?? 0;
        });
      }
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        var results = await Future.wait([
          ApiService.getUserData(userId),
          ApiService.fetchUserProfile(userId),
        ]);

        // PERBAIKAN: Menghapus cast yang tidak perlu jika tipe sudah sesuai
        var userData =
            results[0]; // Jika ApiService.getUserData sudah Future<Map<String, dynamic>>
        var userProfile =
            results[1]; // Jika ApiService.fetchUserProfile sudah Future<Map<String, dynamic>>
        // Atau biarkan sebagai dynamic jika itu tipe returnnya

        // Jika Anda ingin tetap aman dengan tipe, dan results adalah List<dynamic>:
        // final Map<String, dynamic> userData = Map<String, dynamic>.from(results[0] as Map);
        // final Map<String, dynamic> userProfile = Map<String, dynamic>.from(results[1] as Map);
        // Namun, jika linter mengatakan tidak perlu, berarti `results[0]` sudah bisa diakses sebagai Map.

        await SharedPrefs.saveUserProfile(
          // ignore: unnecessary_cast
          userProfile as Map<String, dynamic>,
        ); // Cast di sini mungkin masih perlu jika userProfile adalah dynamic
        await SharedPrefs.saveUserBalance(userData["balance"]?.toString());
        await SharedPrefs.saveUserPoints(userData["points"]?.toString());

        if (mounted) {
          setState(() {
            username =
                (userProfile["full_name"]?.isEmpty ?? true)
                    ? "Pengguna Baru"
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
                (userProfile["profile_picture"]?.isEmpty ?? true)
                    ? null
                    : userProfile["profile_picture"];
            saldo =
                double.tryParse(userData["balance"]?.toString() ?? "0.00") ??
                0.00;
            poin = int.tryParse(userData["points"]?.toString() ?? "0") ?? 0;
          });
        }
      } catch (e) {
        print(
          "Gagal memuat data user dari API, menggunakan data lokal jika ada: $e",
        );
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Konfirmasi Logout",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: titleTextColor,
              ),
            ),
            content: Text(
              "Apakah Anda yakin ingin keluar dari akun ini?",
              style: GoogleFonts.poppins(color: secondaryTextColor),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Batal",
                  style: GoogleFonts.poppins(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await SharedPrefs.clearUserData();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                child: Text(
                  "Logout",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          "Profil Saya",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appBarColor,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: primaryAccentColor,
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(color: primaryAccentColor),
                )
                : username == null && !isLoading
                ? _buildLoginPrompt()
                : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileHeaderCard(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 20),
                      _buildInfoDetailsCard(),
                      const SizedBox(height: 24),
                      _buildActionButton(
                        "Logout Akun",
                        Colors.red.shade600,
                        _confirmLogout,
                        icon: Icons.logout_rounded,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              "Anda Belum Login",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: titleTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan login untuk melihat dan mengelola profil Anda.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              "Login Sekarang",
              primaryAccentColor,
              () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: Icons.login_rounded,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfilePicture(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  username ?? "Pengguna",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: titleTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  "Edit Profil",
                  primaryAccentColor,
                  () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        // PERBAIKAN: Menghapus 'const' jika EditProfilePage tidak punya const constructor
                        builder: (context) => EditProfilePage(),
                      ),
                    );
                    if (result == true && mounted) {
                      _loadUserData();
                    }
                  },
                  isSmall: true,
                  icon: Icons.edit_note_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            "Poin Anda",
            "$poin Poin",
            Icons.star_border_purple500_rounded,
            Colors.amber.shade700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            "Saldo Anda",
            "Rp ${saldo.toStringAsFixed(0)}",
            Icons.account_balance_wallet_outlined,
            primaryAccentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    bool isPlaceholder =
        (title.contains("Poin") &&
            poin == 0 &&
            (username != "Pengguna Baru" && username != null)) ||
        (title.contains("Saldo") &&
            saldo == 0.00 &&
            (username != "Pengguna Baru" && username != null));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  isPlaceholder
                      ? placeholderColor.withOpacity(0.8)
                      : titleTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            "Nomor Telepon",
            phoneNumber ?? "Belum diinput",
            Icons.phone_iphone_rounded,
            primaryAccentColor,
          ),
          Divider(
            color: Colors.grey.shade200,
            height: 20,
            thickness: 0.8,
            indent: 16,
            endIndent: 16,
          ),
          _buildInfoRow(
            "Alamat Lengkap",
            address ?? "Belum diinput",
            Icons.location_city_rounded,
            primaryAccentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    VoidCallback onPressed, {
    bool isSmall = false,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      height: isSmall ? 40 : 50,
      width: isFullWidth ? double.infinity : (isSmall ? null : double.infinity),
      child: ElevatedButton.icon(
        icon:
            icon != null
                ? Icon(icon, size: isSmall ? 18 : 20, color: Colors.white)
                : const SizedBox.shrink(),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 20,
            vertical: isSmall ? 8 : 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryAccentColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 52,
        backgroundColor: primaryAccentColor.withOpacity(0.15),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              (profilePicture != null && profilePicture!.isNotEmpty)
                  ? CachedNetworkImageProvider(profilePicture!)
                  : null,
          child:
              (profilePicture == null || profilePicture!.isEmpty)
                  ? Icon(
                    Icons.person_outline_rounded,
                    size: 50,
                    color: Colors.grey.shade500,
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    bool isPlaceholderValue = (value == "Belum diinput" || value == "-");
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Aksi edit bisa ditambahkan di sini jika diperlukan
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            isPlaceholderValue
                                ? FontWeight.normal
                                : FontWeight.w600,
                        color:
                            isPlaceholderValue
                                ? placeholderColor
                                : titleTextColor,
                        fontStyle:
                            isPlaceholderValue
                                ? FontStyle.italic
                                : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
