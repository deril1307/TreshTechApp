// ignore_for_file: await_only_futures
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
import 'package:tubes_mobile/utils/connectivity_checker.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tubes_mobile/screens/riwayat_screen.dart';

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
    String? savedUserId = SharedPrefs.getUserId();
    String? savedUsername = SharedPrefs.getUsername();
    double savedSaldo = SharedPrefs.getSaldo();
    int savedPoin = SharedPrefs.getPoin();
    String? savedProfilePicture = SharedPrefs.getProfilePicture();

    if (savedUserId == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() {
      userId = savedUserId;
      username = savedUsername ?? "Default Username";
      saldo = savedSaldo;
      poin = savedPoin;
      profilePicture = savedProfilePicture ?? "";
      isLoading = false;
    });

    // ignore: unnecessary_null_comparison
    if (savedUsername == null || savedSaldo == null || savedPoin == null) {
      try {
        var userData = await ApiService.getUserData(savedUserId);
        var userProfile = await ApiService.fetchUserProfile(savedUserId);
        if (mounted) {
          setState(() {
            userId = savedUserId;
            username = userData["username"] ?? savedUsername;
            profilePicture = userProfile["profile_picture"];
            saldo =
                double.tryParse(userData["balance"].toString()) ?? savedSaldo;
            poin = int.tryParse(userData["points"].toString()) ?? savedPoin;
            isLoading = false;
          });
        }
        await SharedPrefs.saveUserData(userId!, username!, saldo, poin);
        await SharedPrefs.saveProfilePicture(profilePicture ?? "");
        saldo = SharedPrefs.getSaldo();
        poin = SharedPrefs.getPoin();
      } catch (e) {
        setState(() {
          userId = savedUserId;
          username = savedUsername;
          saldo = savedSaldo;
          poin = savedPoin;
          profilePicture = savedProfilePicture ?? "";
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUser();
  }

  void _startAutoRefresh() {
    // Timer yang memanggil _refreshData setiap 5 detik
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "TrashTechBank",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
        leading: IconButton(
          icon: Icon(Icons.notifications, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RiwayatScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundImage:
                  profilePicture != null && profilePicture!.isNotEmpty
                      ? NetworkImage(profilePicture!)
                      : AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            username != null ? "Hi, $username!" : "Hi!",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: 30),
                          _buildBalanceCard(),
                          SizedBox(height: 30),
                          _buildMenuGrid(),
                        ],
                      ),
                    ),
          ),
          ConnectivityChecker(),
        ],
      ),
    );
  }

  // card
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 63, 168, 69), // hijau uang
            const Color.fromARGB(255, 13, 141, 19),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Saldo & Poin Anda",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            ],
          ),
          SizedBox(height: 15),

          // Saldo
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rp ${saldo.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                Icon(
                  Icons.monetization_on,
                  color: Colors.yellowAccent,
                  size: 26,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),

          // Poin
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$poin TrashTechPoin",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Icon(Icons.star, color: Colors.amberAccent, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16), // Tambahkan padding agar tidak mepet
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              // Menu Tukar
              _buildMenuItem(
                label: "Tukar",
                icon: FontAwesomeIcons.gift,
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PenukaranPoinScreen()),
                  );
                },
              ),

              // Menu Tarik
              _buildMenuItem(
                label: "Tarik",
                icon: FontAwesomeIcons.wallet,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TarikSaldoScreen()),
                  );
                },
              ),

              // Menu Kategori
              _buildMenuItem(
                label: "Kategori",
                icon: FontAwesomeIcons.trashAlt,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => KategoriSampahScreen()),
                  );
                },
              ),

              // Menu Setor
              _buildMenuItem(
                label: "Setor",
                icon: FontAwesomeIcons.recycle,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SetorSampahScreen()),
                  );
                },
              ),

              // Menu Info
              _buildMenuItem(
                label: "Info",
                icon: FontAwesomeIcons.infoCircle,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InfoScreen()),
                  );
                },
              ),

              // Menu Leaderboard
              _buildMenuItem(
                label: "Rank",
                icon: FontAwesomeIcons.trophy,
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LeaderboardScreen()),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildAktivitasTerbaruCard(),
          SizedBox(height: 24), // Tambahan spacing bawah
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
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: _buildMiniMenuButton(label, icon, color, onTap),
    );
  }

  Widget _buildAktivitasTerbaruCard() {
    List<Map<String, String>> aktivitas = [
      {"judul": "Setor Sampah Organik", "tanggal": "5 Mei 2025"},
      {"judul": "Tukar Poin dengan Voucher", "tanggal": "3 Mei 2025"},
      {"judul": "Tarik Saldo ke Dana", "tanggal": "1 Mei 2025"},
    ];

    Icon _getIcon(String judul) {
      if (judul.toLowerCase().contains("setor")) {
        return Icon(Icons.delete, color: Colors.orange); // ikon sampah
      } else if (judul.toLowerCase().contains("tarik")) {
        return Icon(
          Icons.account_balance_wallet,
          color: Colors.green,
        ); // ikon dompet
      } else if (judul.toLowerCase().contains("tukar")) {
        return Icon(Icons.attach_money, color: Colors.red); // ikon uang
      } else {
        return Icon(Icons.history, color: Colors.grey); // default
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Aktivitas Terbaru",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          ...aktivitas.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _getIcon(item["judul"]!),
              title: Text(
                item["judul"]!,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              subtitle: Text(
                item["tanggal"]!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mini button widget for each menu item
  Widget _buildMiniMenuButton(
    String title,
    IconData icon,
    Color color,
    Function onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
