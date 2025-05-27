// ignore_for_file: await_only_futures, unused_import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/screens/info_screen.dart';
import 'dart:async';
import 'package:tubes_mobile/screens/kategori_sampah_screen.dart';
import 'package:tubes_mobile/screens/leaderboard_screen.dart';
import 'package:tubes_mobile/screens/penukaran_poin_screen.dart';
import 'package:tubes_mobile/screens/setor_sampah_screen.dart';
import 'package:tubes_mobile/screens/tarik_saldo_screen.dart';
import 'package:tubes_mobile/screens/profile_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tubes_mobile/screens/riwayat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tubes_mobile/utils/connectivity_checker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  static final GlobalKey<_HomeScreenState> homeScreenKey =
      GlobalKey<_HomeScreenState>();

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userId;
  String? username;
  double saldo = 0;
  int poin = 0;
  bool isLoading = true;
  String? profilePicture;
  late Timer _timer;

  final Color primaryColor = const Color.fromARGB(255, 7, 168, 13);
  final Color primaryLightColor = const Color.fromARGB(255, 66, 199, 73);
  final Color primaryDarkColor = const Color.fromARGB(255, 4, 105, 9);
  final Color scaffoldBgColor = const Color(0xFFF0F4F8);
  final Color cardColor = Colors.white;
  final Color titleTextColor = Colors.green.shade900;
  final Color bodyTextColor = Colors.black.withOpacity(0.75);
  final Color secondaryTextColor = Colors.grey.shade600;
  final Color cardShadowColor = Colors.black.withOpacity(0.06);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;

    if (!isLoading && (userId == null || username == null)) {
      setState(() => isLoading = true);
    }

    String? savedUserId = await SharedPrefs.getUserId();
    String? savedUsername = await SharedPrefs.getUsername();
    double savedSaldo = await SharedPrefs.getSaldo();
    int savedPoin = await SharedPrefs.getPoin();
    String? savedProfilePicture = await SharedPrefs.getProfilePicture();

    if (savedUserId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    if (mounted) {
      setState(() {
        userId = savedUserId;
        username = savedUsername ?? "Pengguna";
        saldo = savedSaldo;
        poin = savedPoin;
        profilePicture = savedProfilePicture;
      });
    }

    // PERBAIKAN: Menggunakan Connectivity().checkConnectivity() secara langsung
    var connectivityResult = await (Connectivity().checkConnectivity());
    // Versi terbaru connectivity_plus mengembalikan List<ConnectivityResult>
    // Jadi kita cek jika tidak mengandung .none
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        var userData = await ApiService.getUserData(savedUserId);
        var userProfile = await ApiService.fetchUserProfile(savedUserId);

        if (mounted) {
          setState(() {
            username =
                (userProfile["full_name"]?.isEmpty ?? true)
                    ? (savedUsername ?? "Pengguna")
                    : userProfile["full_name"];
            profilePicture = userProfile["profile_picture"];
            saldo =
                double.tryParse(userData["balance"].toString()) ?? savedSaldo;
            poin = int.tryParse(userData["points"].toString()) ?? savedPoin;
            isLoading = false;
          });
        }
        await SharedPrefs.saveUserData(userId!, username!, saldo, poin);
        await SharedPrefs.saveProfilePicture(profilePicture ?? "");
      } catch (e) {
        print("Error fetching API data in HomeScreen: $e");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUser();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) _refreshData();
    });
  }

  // ... Sisa dari widget build dan helper method lainnya (_buildHeaderSection, _buildBalanceCard, dll.)
  // TETAP SAMA seperti versi UI yang telah disempurnakan sebelumnya.
  // Anda hanya perlu memastikan metode _loadUser di atas yang digunakan.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "TrashTechBank",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 2.0,
        leading: IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RiwayatScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Hero(
                tag: 'profileAvatar',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.8),
                  backgroundImage:
                      (profilePicture != null && profilePicture!.isNotEmpty)
                          ? CachedNetworkImageProvider(profilePicture!)
                          : const AssetImage(
                                'assets/images/default_profile.png',
                              )
                              as ImageProvider,
                  child:
                      (profilePicture == null || profilePicture!.isEmpty)
                          ? const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 20,
                          )
                          : null,
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (result == true || result == null && mounted) {
                  _refreshData();
                }
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            color: primaryColor,
            child:
                isLoading && userId == null
                    ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                    : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(),
                          _buildMenuGrid(),
                          _buildAktivitasTerbaruCard(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
          ),
          const ConnectivityChecker(), // Widget Anda untuk menampilkan status koneksi
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      decoration: BoxDecoration(
        color: primaryLightColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username != null
                ? "Halo, ${username!.split(" ").first}!"
                : "Selamat Datang!",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            "Kelola sampah, dapatkan poinnya",
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),
          _buildBalanceCard(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDarkColor, primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Aset Anda",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Icon(
                FontAwesomeIcons.wallet,
                color: Colors.white.withOpacity(0.8),
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Rp ${saldo.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2), thickness: 0.8),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                FontAwesomeIcons.solidStar,
                color: Colors.yellowAccent.shade700,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "$poin Poin Reward",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16),
            child: Text(
              "Menu Layanan",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleTextColor,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMenuItem(
                label: "Tukar Poin",
                icon: FontAwesomeIcons.gifts,
                color: Colors.redAccent.shade400,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PenukaranPoinScreen()),
                  );
                },
              ),
              _buildMenuItem(
                label: "Tarik Saldo",
                icon: FontAwesomeIcons.moneyBillWave,
                color: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TarikSaldoScreen()),
                  );
                },
              ),
              _buildMenuItem(
                label: "Kategori",
                icon: FontAwesomeIcons.shapes,
                color: Colors.purple.shade400,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KategoriSampahScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                label: "Setor",
                icon: FontAwesomeIcons.boxOpen,
                color: Colors.orange.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SetorSampahScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                label: "Info",
                icon: FontAwesomeIcons.circleInfo,
                color: Colors.blue.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InfoScreen()),
                  );
                },
              ),
              _buildMenuItem(
                label: "Peringkat",
                icon: FontAwesomeIcons.trophy,
                color: Colors.amber.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                label: "Riwayat",
                icon: FontAwesomeIcons.history,
                color: Colors.teal.shade500,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RiwayatScreen()),
                  );
                },
              ),
              _buildMenuItem(
                label: "Lainnya",
                icon: FontAwesomeIcons.ellipsisH,
                color: Colors.grey.shade600,
                onTap: () {
                  // Aksi untuk menu lainnya
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2.0,
      shadowColor: cardShadowColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: titleTextColor.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAktivitasTerbaruCard() {
    List<Map<String, String>> aktivitas =
        SharedPrefs.getRiwayat().reversed.toList();

    IconData _getIconForActivity(String? kegiatan) {
      if (kegiatan == null) return FontAwesomeIcons.history;
      String lowerKegiatan = kegiatan.toLowerCase();
      if (lowerKegiatan.contains("setor")) return FontAwesomeIcons.recycle;
      if (lowerKegiatan.contains("tarik saldo"))
        return FontAwesomeIcons.moneyBillTransfer;
      if (lowerKegiatan.contains("penukaran poin"))
        return FontAwesomeIcons.gifts;
      return FontAwesomeIcons.history;
    }

    Color _getColorForActivity(String? kegiatan) {
      if (kegiatan == null) return Colors.grey.shade400;
      String lowerKegiatan = kegiatan.toLowerCase();
      if (lowerKegiatan.contains("setor")) return Colors.orange.shade700;
      if (lowerKegiatan.contains("tarik saldo")) return primaryDarkColor;
      if (lowerKegiatan.contains("penukaran poin"))
        return Colors.redAccent.shade400;
      return Colors.grey.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Aktivitas Terbaru",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleTextColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RiwayatScreen()),
                    );
                  },
                  child: Text(
                    "Lihat Semua",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (aktivitas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    "Belum ada aktivitas terbaru.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: aktivitas.length > 3 ? 3 : aktivitas.length,
                itemBuilder: (context, index) {
                  final item = aktivitas[index];
                  final iconData = _getIconForActivity(item["kegiatan"]);
                  final iconColor = _getColorForActivity(item["kegiatan"]);
                  String formattedDate = "Tanggal tidak valid";
                  if (item["tanggal"] != null) {
                    try {
                      DateTime parsedDate = DateTime.parse(item["tanggal"]!);
                      formattedDate =
                          "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
                    } catch (e) {
                      // Biarkan
                    }
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 0,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.15),
                      child: FaIcon(iconData, color: iconColor, size: 18),
                      radius: 22,
                    ),
                    title: Text(
                      item["kegiatan"] ?? 'Aktivitas',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: bodyTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  );
                },
                separatorBuilder:
                    (context, index) =>
                        Divider(color: Colors.grey.shade200, height: 1),
              ),
          ],
        ),
      ),
    );
  }
}
