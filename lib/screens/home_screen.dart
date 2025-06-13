// ignore_for_file: await_only_futures, unused_import, duplicate_import

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:tubes_mobile/screens/info_screen.dart'; // DIHAPUS KARENA TIDAK DIGUNAKAN LAGI
import 'dart:async';
import 'package:tubes_mobile/screens/kategori_sampah_screen.dart';
import 'package:tubes_mobile/screens/leaderboard_screen.dart';
import 'package:tubes_mobile/screens/penukaran_poin_screen.dart';
import 'package:tubes_mobile/screens/setor_sampah_screen.dart';
import 'package:tubes_mobile/screens/tarik_saldo_screen.dart';
import 'package:tubes_mobile/screens/profile/profile_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tubes_mobile/screens/riwayat/riwayat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tubes_mobile/utils/connectivity_checker.dart';

import '../main.dart';

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

    if (userId == null && username == null) {
      if (mounted) setState(() => isLoading = true);
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

    var connectivityResult = await (Connectivity().checkConnectivity());
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
        if (userId != null && username != null) {
          await SharedPrefs.saveUserData(userId!, username!, saldo, poin);
          await SharedPrefs.saveProfilePicture(profilePicture ?? "");
        }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("TrashTechBank"),
        leading: IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 26),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RiwayatScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDarkMode ? "Mode Terang" : "Mode Gelap",
            onPressed: () {
              MyApp.of(
                context,
              )?.changeTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Hero(
                tag: 'profileAvatar',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      isDarkMode
                          ? Colors.white24
                          : Colors.white.withOpacity(0.8),
                  backgroundImage:
                      (profilePicture != null && profilePicture!.isNotEmpty)
                          ? CachedNetworkImageProvider(profilePicture!)
                          : const AssetImage(
                                'assets/images/default_profile.png',
                              )
                              as ImageProvider,
                  child:
                      (profilePicture == null || profilePicture!.isEmpty)
                          ? Icon(Icons.person, color: theme.hintColor, size: 20)
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
            color: theme.primaryColor,
            child:
                isLoading && userId == null
                    ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    )
                    : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(context),
                          _buildMenuGrid(context),
                          _buildAktivitasTerbaruCard(context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
          ),
          const ConnectivityChecker(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      decoration: BoxDecoration(
        color: customColors.headerSectionBackground,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
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
          _buildBalanceCard(context),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: customColors.balanceCardGradient!,
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

  Widget _buildMenuGrid(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16),
            child: Text("Menu Layanan", style: theme.textTheme.headlineSmall),
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
                context: context,
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
                context: context,
                label: "Tarik Saldo",
                icon: FontAwesomeIcons.moneyBillWave,
                color: theme.primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TarikSaldoScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context: context,
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
                context: context,
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
                context: context,
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
              //  MENU ITEM RIWAYAT, INFO, DAN LAINNYA DIHAPUS DARI SINI
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2.0,
      shadowColor: theme.shadowColor.withOpacity(isDarkMode ? 0.15 : 0.06),
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
                  color: color.withOpacity(isDarkMode ? 0.25 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAktivitasTerbaruCard(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final isDarkMode = theme.brightness == Brightness.dark;

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
      if (lowerKegiatan.contains("tarik saldo")) return theme.primaryColorDark;
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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(isDarkMode ? 0.1 : 0.05),
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
                Text("Aktivitas Terbaru", style: theme.textTheme.headlineSmall),
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
                      color: theme.primaryColor,
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
                      color: customColors.secondaryTextColor,
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
                      // Biarkan tanggal tidak valid jika parsing gagal
                    }
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 0,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(
                        isDarkMode ? 0.25 : 0.15,
                      ),
                      child: FaIcon(iconData, color: iconColor, size: 18),
                      radius: 22,
                    ),
                    title: Text(
                      item["kegiatan"] ?? 'Aktivitas',
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      formattedDate,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
                separatorBuilder:
                    (context, index) =>
                        Divider(color: theme.dividerColor, height: 1),
              ),
          ],
        ),
      ),
    );
  }
}
