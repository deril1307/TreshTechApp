// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Jangan lupa import
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Untuk placeholder yang lebih baik
import 'package:flutter/services.dart'; // Untuk SystemUiOverlayStyle

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;
  String? error;

  final Color primaryColor = Color.fromARGB(255, 7, 168, 13);
  final Color scaffoldBgColor = Colors.grey.shade100;
  final Color secondaryTextColor = Colors.grey.shade700;
  final Color darkTextColor = Colors.black87;
  final Color listBgColor = Colors.white;
  final Color goldColor = const Color(0xFFE6B400);
  final Color silverColor = const Color(0xFFB0B0B0);
  final Color bronzeColor = const Color(0xFFA05A2C);

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ApiService.getLeaderboard();
      if (!mounted) return;
      setState(() {
        data.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
        leaderboardData = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error =
            "Gagal memuat data. Periksa koneksi internet Anda."; // Pesan error lebih ramah
        isLoading = false;
      });
    }
  }

  Widget _buildErrorStateWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded, // Icon lebih relevan
              color: Colors.red.shade400, // Warna lebih kontras
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              "Oops, Koneksi Bermasalah!",
              style: GoogleFonts.poppins(
                fontSize: 20, // Ukuran font disesuaikan
                fontWeight: FontWeight.bold,
                color: darkTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                "Coba Lagi",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600, // Lebih tebal
                ),
              ),
              onPressed: fetchLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30, // Padding disesuaikan
                  vertical: 14,
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientDataWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined, // Icon yang lebih sesuai
              color: Colors.grey.shade500, // Warna lebih lembut
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              "Data Belum Cukup",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Minimal 3 pengguna aktif dibutuhkan untuk menampilkan podium dan peringkat.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                "Refresh Data",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: fetchLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboardWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_rounded, // Icon yang lebih sesuai
              color: Colors.grey.shade500,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              "Papan Peringkat Kosong",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Saat ini belum ada data peringkat untuk ditampilkan.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Atur warna status bar agar konsisten dengan AppBar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryColor, // Samakan dengan AppBar
        statusBarIconBrightness:
            Brightness.light, // Ikon terang jika background gelap
      ),
    );

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Papan Peringkat",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2.0, // Sedikit shadow
        // Tombol refresh di AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed:
                isLoading ? null : fetchLeaderboard, // Nonaktifkan saat loading
            tooltip: "Refresh Peringkat",
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : error != null
              ? _buildErrorStateWidget(error!)
              : leaderboardData
                  .isEmpty // Cek jika kosong dulu
              ? _buildEmptyLeaderboardWidget()
              : leaderboardData.length <
                  3 // Baru cek jika kurang dari 3
              ? _buildInsufficientDataWidget()
              : Column(
                // Layout utama jika data cukup
                children: [
                  // Bagian Podium (Top 3)
                  Container(
                    padding: const EdgeInsets.only(
                      top: 24.0,
                      bottom: 20.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(
                        0.05,
                      ), // Warna latar podium
                      // borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (leaderboardData.length > 1)
                          _buildTopUser(
                            leaderboardData[1],
                            2,
                            silverColor,
                            "nd",
                          ),
                        if (leaderboardData.isNotEmpty)
                          _buildTopUser(leaderboardData[0], 1, goldColor, "st"),
                        if (leaderboardData.length > 2)
                          _buildTopUser(
                            leaderboardData[2],
                            3,
                            bronzeColor,
                            "rd",
                          ),
                      ],
                    ),
                  ),
                  // Daftar Peringkat Lainnya
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 0,
                      ), // Beri jarak dari podium
                      decoration: BoxDecoration(
                        color: listBgColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        itemCount:
                            leaderboardData.length > 3
                                ? leaderboardData.length - 3
                                : 0,
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ), // Padding untuk list
                        separatorBuilder:
                            (_, __) => Divider(
                              color: Colors.grey.shade200,
                              height: 1,
                              thickness: 1,
                              indent: 16, // Indent agar tidak full width
                              endIndent: 16,
                            ),
                        itemBuilder: (context, index) {
                          final user = leaderboardData[index + 3];
                          final rank = index + 4;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10.0, // Padding vertikal lebih besar
                              horizontal: 8.0,
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36, // Lebar rank konsisten
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$rank", // Hanya angka rank
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 22, // Ukuran avatar konsisten
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: CachedNetworkImageProvider(
                                    // Gunakan CachedNetworkImageProvider
                                    _getAvatarUrl(user['username'] ?? 'User'),
                                  ),
                                  onBackgroundImageError: (e, s) {
                                    // Handle error jika perlu, misal tampilkan inisial
                                  },
                                ),
                              ],
                            ),
                            title: Text(
                              user["username"] ?? "User Tanpa Nama",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: darkTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              "${user["points"] ?? 0} Poin",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600, // Lebih tebal
                                color: primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTopUser(
    Map<String, dynamic> user,
    int rank,
    Color rankColor,
    String rankSuffix,
  ) {
    final double baseHeight = 100; // Ketinggian dasar untuk rank 3
    final double heightFactor;
    // Variabel untuk ukuran dan spasi yang disesuaikan
    double avatarRadius;
    double usernameFontSize;
    double pointsFontSize;
    double rankBadgeFontSize;
    double spaceAfterAvatar;
    double spaceAfterUsername;
    EdgeInsetsGeometry containerPadding;

    if (rank == 1) {
      heightFactor = 1.45;
      avatarRadius = 32; // Sebelumnya 38
      usernameFontSize = 12; // Sebelumnya 13
      pointsFontSize = 10; // Sebelumnya 11
      rankBadgeFontSize = 16;
      spaceAfterAvatar = 4; // Sebelumnya 6
      spaceAfterUsername = 2; // Sebelumnya 3
      containerPadding = const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 6,
      ); // Sebelumnya 10
    } else if (rank == 2) {
      heightFactor = 1.20;
      avatarRadius = 28; // Sebelumnya 32
      usernameFontSize = 11; // Sebelumnya 12
      pointsFontSize = 9; // Sebelumnya 10
      rankBadgeFontSize = 15;
      spaceAfterAvatar = 4; // Sebelumnya 6
      spaceAfterUsername = 2; // Sebelumnya 3
      containerPadding = const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 6,
      ); // Sebelumnya 10
    } else {
      // Rank 3
      heightFactor = 1.0;
      avatarRadius = 24; // Sebelumnya 28
      usernameFontSize = 10; // Sebelumnya 11
      pointsFontSize = 8; // Sebelumnya 9
      rankBadgeFontSize = 14;
      spaceAfterAvatar = 4; // Sebelumnya 6
      spaceAfterUsername = 2; // Sebelumnya 3
      containerPadding = const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 6,
      ); // Sebelumnya 10
    }

    final String username = user["username"] ?? "User";
    final int points = user["points"] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1) // Mahkota hanya untuk rank 1
          Icon(
            Icons.emoji_events_rounded,
            color: rankColor.withOpacity(0.9),
            size: 32,
          ),
        if (rank == 1) const SizedBox(height: 4),
        Container(
          height: baseHeight * heightFactor,
          width: 95, // Lebar disesuaikan
          padding: containerPadding, // Gunakan padding yang disesuaikan
          decoration: BoxDecoration(
            color: listBgColor, // Warna dasar putih
            borderRadius: BorderRadius.circular(16), // Radius lebih besar
            border: Border.all(
              color: rankColor,
              width: 2.5,
            ), // Border lebih tebal
            boxShadow: [
              BoxShadow(
                color: rankColor.withOpacity(0.25), // Shadow dengan warna rank
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  _getAvatarUrl(username),
                ),
                radius: avatarRadius, // Gunakan radius yang disesuaikan
                backgroundColor: Colors.grey.shade200,
                onBackgroundImageError: (e, s) {},
              ),
              SizedBox(
                height: spaceAfterAvatar,
              ), // Gunakan spasi yang disesuaikan
              Text(
                username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize:
                      usernameFontSize, // Gunakan font size yang disesuaikan
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              SizedBox(
                height: spaceAfterUsername,
              ), // Gunakan spasi yang disesuaikan
              Text(
                "$points Poin",
                style: GoogleFonts.poppins(
                  color: secondaryTextColor,
                  fontSize:
                      pointsFontSize, // Gunakan font size yang disesuaikan
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: rankColor.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            "$rank$rankSuffix", // Menggunakan rankSuffix
            style: GoogleFonts.poppins(
              fontSize: rankBadgeFontSize, // Gunakan font size yang disesuaikan
              fontWeight: FontWeight.bold,
              color:
                  rank == 1
                      ? Colors.black.withOpacity(0.75)
                      : Colors.white, // Warna teks rank badge
            ),
          ),
        ),
      ],
    );
  }

  String _getAvatarUrl(String name) {
    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=128&font-size=0.35&bold=true";
  }
}
