import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/screens/kategori_sampah_screen.dart';
import 'package:tubes_mobile/screens/penukaran_poin_screen.dart';
import 'package:tubes_mobile/screens/profile_screen.dart';
import 'package:tubes_mobile/utils/connectivity_checker.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/services/api_service.dart';

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
      print(" Gagal mengambil data API, menggunakan data offline.");
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 15, // Ukuran avatar
              backgroundImage:
                  profilePicture != null && profilePicture!.isNotEmpty
                      ? NetworkImage(profilePicture!) // Gambar profil dari URL
                      : AssetImage('assets/images/default_avatar.png')
                          as ImageProvider, // Gambar default jika tidak ada
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
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
                    SizedBox(height: 20),
                    _buildBalanceCard(),
                    SizedBox(height: 30),
                    _buildMenuGrid(),
                  ],
                ),
              ),
          ConnectivityChecker(), // Tambahkan pengecekan konektivitas
        ],
      ),
    );
  }

  // Kartu besar untuk Saldo dan Poin
  Widget _buildBalanceCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(2, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Saldo & Poin Anda",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Rp ${saldo.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 5),
          Text(
            "$poin Poin",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
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
        childAspectRatio: 1.5, // Card lebih kecil
        children: [
          _buildMenuButton("Riwayat", Icons.history, Colors.blue),
          _buildMenuButton("Tukar Poin", Icons.card_giftcard, Colors.red, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PenukaranPoinScreen()),
            );
          }),
          _buildMenuButton("Tarik Saldo", Icons.attach_money, Colors.green),
          _buildMenuButton(
            "Kategori Sampah",
            Icons.category,
            Colors.purple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KategoriSampahScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color), // Ikon lebih kecil
            SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
