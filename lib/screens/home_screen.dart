// ignore_for_file: await_only_futures
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/screens/kategori_sampah_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
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
        // print("Saldo terbaru: $saldo, Poin terbaru: $poin");
      } catch (e) {
        // print("Menggunakan data offline.");
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
            // Navigate to RiwayatScreen when the notification icon is clicked
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
          SizedBox(width: 10), // Add spacing between icons in the AppBar
        ],
      ),
      body: Stack(
        children: [
          // Wrap the body with RefreshIndicator
          RefreshIndicator(
            onRefresh: _refreshData,
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20, // Add more vertical spacing
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Text(
                            username != null
                                ? "Selamat Datang, $username!"
                                : "Selamat Datang!",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: 30), // Add spacing after greeting
                          _buildBalanceCard(), // Add balance card widget
                          SizedBox(
                            height: 40,
                          ), // Add more spacing between components
                          _buildMenuGrid(), // Display the menu grid
                        ],
                      ),
                    ),
          ),
          ConnectivityChecker(), // Display connection status
        ],
      ),
    );
  }

  // Balance card showing the user's balance and points
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 63, 168, 69),
            const Color.fromARGB(255, 13, 141, 19),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
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

          // Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rp ${saldo.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.monetization_on, color: Colors.white, size: 24),
            ],
          ),
          SizedBox(height: 10),

          // Points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$poin TrashTechPoin",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              Icon(
                Icons.star,
                color: const Color.fromARGB(255, 255, 255, 255),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Grid menu
  Widget _buildMenuGrid() {
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              shrinkWrap: true,
              physics:
                  NeverScrollableScrollPhysics(), // biar scroll-nya satu saja
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMiniMenuButton(
                    "Tukar",
                    FontAwesomeIcons.gift,
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PenukaranPoinScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMiniMenuButton(
                    "Tarik",
                    FontAwesomeIcons.wallet,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TarikSaldoScreen()),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMiniMenuButton(
                    "Kategori",
                    FontAwesomeIcons.trashAlt,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KategoriSampahScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMiniMenuButton(
                    "Setor",
                    FontAwesomeIcons.recycle,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SetorSampahScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildAktivitasTerbaruCard(), // Sekarang muncul tepat di bawah grid
          ],
        ),
      ),
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
