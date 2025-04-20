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

class HomeScreen extends StatefulWidget {
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
    String? savedUsername = await SharedPrefs.getUsername();
    double savedSaldo = SharedPrefs.getSaldo();
    int savedPoin = SharedPrefs.getPoin();

    if (savedUserId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var userData = await ApiService.getUserData(savedUserId);
      var userProfile = await ApiService.fetchUserProfile(savedUserId);
      if (mounted) {
        setState(() {
          userId = savedUserId;
          username = userData["username"] ?? savedUsername;
          profilePicture = userProfile["profile_picture"];
          saldo = double.tryParse(userData["balance"].toString()) ?? savedSaldo;
          poin = int.tryParse(userData["points"].toString()) ?? savedPoin;
          isLoading = false;
        });
      }
      await SharedPrefs.saveUserData(userId!, username!, saldo, poin);
    } catch (e) {
      print("menggunakan data offline.");
      setState(() {
        userId = savedUserId;
        username = savedUsername;
        saldo = savedSaldo;
        poin = savedPoin;
        isLoading = false;
      });
    }
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
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 18, // Ukuran avatar yang lebih besar
              backgroundImage:
                  profilePicture != null && profilePicture!.isNotEmpty
                      ? NetworkImage(profilePicture!) // Gambar profil dari URL
                      : AssetImage('assets/images/default_avatar.png')
                          as ImageProvider, // Gambar default jika tidak ada
              backgroundColor:
                  Colors
                      .white, // Memberikan latar belakang putih di sekitar avatar
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          SizedBox(width: 10), // Memberikan jarak antar ikon di AppBar
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15, // Menambah jarak vertikal lebih banyak
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
                    SizedBox(height: 30), // Menambah jarak setelah greeting
                    _buildBalanceCard(), // Menambahkan card saldo
                    SizedBox(
                      height: 40,
                    ), // Menambah jarak lebih banyak antar komponen
                    _buildMenuGrid(), // Menampilkan menu grid
                  ],
                ),
              ),
          ConnectivityChecker(), // Menampilkan status koneksi
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity, // Card memenuhi lebar layar
      margin: EdgeInsets.symmetric(vertical: 20), // Margin vertikal untuk card
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
          // Judul Card
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

          // Poin
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

  // Menu kecil untuk navigasi
  Widget _buildMenuGrid() {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
        padding: EdgeInsets.all(
          15,
        ), // Menambahkan padding agar grid lebih teratur
        children: [
          _buildMenuButton("Riwayat", FontAwesomeIcons.history, Colors.blue),
          _buildMenuButton("Tukar Poin", FontAwesomeIcons.gift, Colors.red, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PenukaranPoinScreen()),
            );
          }),
          _buildMenuButton(
            "Tarik Saldo",
            FontAwesomeIcons.wallet,
            Colors.green,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TarikSaldoScreen()),
              );
            },
          ),
          _buildMenuButton(
            "Kategori Sampah",
            FontAwesomeIcons.trashAlt,
            Colors.purple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KategoriSampahScreen()),
              );
            },
          ),
          _buildMenuButton(
            "Setor Sampah",
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

  // Membuat tombol menu dengan desain yang lebih menarik
  Widget _buildMenuButton(
    String title,
    IconData icon,
    Color color, [
    VoidCallback? onTap,
  ]) {
    return GestureDetector(
      onTap: onTap ?? () => print("Navigasi ke halaman $title"),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12), // Perbaikan border radius
          border: Border.all(
            color: color,
            width: 2,
          ), // Menambah ketebalan border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6, // Menambahkan blur lebih besar untuk efek 3D
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: color,
            ), // Menambah ukuran ikon untuk terlihat lebih jelas
            SizedBox(height: 10), // Jarak lebih besar antara ikon dan teks
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14, // Meningkatkan ukuran teks agar lebih terbaca
                fontWeight:
                    FontWeight
                        .w600, // Mengubah ke berat font yang lebih konsisten
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
