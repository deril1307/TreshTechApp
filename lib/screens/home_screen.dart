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
    // Ambil data user dari SharedPrefs
    String? savedUserId = SharedPrefs.getUserId();
    String? savedUsername = await SharedPrefs.getUsername();
    double savedSaldo = SharedPrefs.getSaldo();
    int savedPoin = SharedPrefs.getPoin();

    // Jika data user tidak ada, langsung set loading ke false
    if (savedUserId == null) {
      setState(() => isLoading = false);
      return;
    }

    // Jika data user sudah ada di SharedPrefs, langsung set state tanpa memanggil API
    setState(() {
      userId = savedUserId;
      username = savedUsername ?? "Default Username";
      saldo = savedSaldo;
      poin = savedPoin;
      isLoading = false;
    });

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

        // Simpan data terbaru ke SharedPrefs
        await SharedPrefs.saveUserData(userId!, username!, saldo, poin);

        // Ambil saldo dan poin terbaru dari SharedPrefs
        saldo = await SharedPrefs.getSaldo();
        poin = await SharedPrefs.getPoin();

        print("Saldo terbaru: $saldo, Poin terbaru: $poin");
      } catch (e) {
        print("Menggunakan data offline.");
        // Jika gagal ambil data dari API, gunakan data dari SharedPrefs
        setState(() {
          userId = savedUserId;
          username = savedUsername;
          saldo = savedSaldo;
          poin = savedPoin;
          isLoading = false;
        });
      }
    }
  }

  // Function to handle refresh
  Future<void> _refreshData() async {
    await _loadUser(); // Reload user data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "TrashTech",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.green,
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
                          as ImageProvider, // Default image if no profile picture
              backgroundColor: Colors.white, // White background for the avatar
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
                        horizontal: 20,
                        vertical: 15, // Add more vertical spacing
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
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
                "$poin Poin",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade200,
                ),
              ),
              Icon(Icons.star, color: Colors.orange.shade200, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  // Grid menu for navigation similar to Gojek's interface
  Widget _buildMenuGrid() {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 4, // More columns like in Gojek
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9, // Higher than width for more height
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        children: [
          _buildMiniMenuButton("Tukar", FontAwesomeIcons.gift, Colors.red, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PenukaranPoinScreen()),
            );
          }),
          _buildMiniMenuButton(
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
          _buildMiniMenuButton(
            "Kategori",
            FontAwesomeIcons.trashAlt,
            Colors.purple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KategoriSampahScreen()),
              );
            },
          ),
          _buildMiniMenuButton(
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
