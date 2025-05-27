// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Jangan lupa import
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Untuk placeholder yang lebih baik

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key}); // Tambahkan const jika memungkinkan

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;
  String? error;

  // Definisikan warna tema untuk konsistensi
  final Color primaryColor = const Color.fromARGB(255, 7, 168, 13);
  final Color scaffoldBgColor = Colors.green.shade50;
  final Color secondaryTextColor = Colors.grey.shade700;
  final Color darkTextColor = Colors.black87;
  final Color listBgColor = Colors.white;
  final Color goldColor = const Color(0xFFFFD700);
  final Color silverColor = const Color(0xFFC0C0C0);
  final Color bronzeColor = const Color(0xFFCD7F32);

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null; // Reset error state
    });
    try {
      final data = await ApiService.getLeaderboard();
      if (!mounted) return;
      setState(() {
        // Urutkan data berdasarkan poin secara descending jika belum diurutkan dari API
        data.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
        leaderboardData = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
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
              Icons.error_outline_rounded,
              color: Colors.red.shade300,
              size: 70,
            ),
            const SizedBox(height: 20),
            Text(
              "Oops, terjadi kesalahan!",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Gagal memuat data. Periksa koneksi internet Anda.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                "Coba Lagi",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: fetchLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
              Icons.people_outline_rounded,
              color: Colors.grey.shade400,
              size: 70,
            ),
            const SizedBox(height: 20),
            Text(
              "Data Leaderboard Belum Cukup",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Minimal 3 pengguna dibutuhkan untuk menampilkan podium.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                "Refresh Data",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: fetchLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        elevation: 1.0,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : error != null
              ? _buildErrorStateWidget(error!)
              : leaderboardData.length < 3 && leaderboardData.isNotEmpty
              ? _buildInsufficientDataWidget()
              : leaderboardData.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.leaderboard_outlined,
                        color: Colors.grey.shade400,
                        size: 70,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Leaderboard Kosong",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Belum ada data untuk ditampilkan.",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: secondaryTextColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "",
                          style: GoogleFonts.poppins(
                            color: secondaryTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 8.0, // Padding horizontal untuk Row Top 3
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (leaderboardData.length > 1)
                          // PERBAIKAN: Bungkus _buildTopUser dengan Flexible atau Expanded jika diperlukan
                          // Namun, karena _buildTopUser memiliki width tetap, pastikan total width + spacing cukup.
                          // Jika tidak, pertimbangkan mengurangi width atau padding di _buildTopUser
                          _buildTopUser(leaderboardData[1], 2, silverColor),
                        if (leaderboardData.isNotEmpty)
                          _buildTopUser(leaderboardData[0], 1, goldColor),
                        if (leaderboardData.length > 2)
                          _buildTopUser(leaderboardData[2], 3, bronzeColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 24,
                        left: 16, // Padding kiri untuk list
                        right: 16, // Padding kanan untuk list
                      ),
                      decoration: BoxDecoration(
                        color: listBgColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        itemCount:
                            leaderboardData.length > 3
                                ? leaderboardData.length - 3
                                : 0,
                        padding: EdgeInsets.zero,
                        separatorBuilder:
                            (_, __) => Divider(
                              color: Colors.grey.shade200,
                              height: 1,
                              thickness: 1,
                            ),
                        itemBuilder: (context, index) {
                          final user = leaderboardData[index + 3];
                          final rank = index + 4;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal:
                                  0, // Kurangi horizontal padding ListTile jika ada padding di Container luar
                            ),
                            leading: Row(
                              // Menggunakan Row untuk leading agar lebih fleksibel
                              mainAxisSize:
                                  MainAxisSize
                                      .min, // Penting untuk Row dalam leading
                              children: [
                                Container(
                                  width: 32, // Lebar tetap untuk rank agar rapi
                                  alignment: Alignment.center,
                                  child: Text(
                                    "#$rank",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14, // Sedikit dikecilkan
                                      fontWeight: FontWeight.bold,
                                      color: secondaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // Jarak antara rank dan avatar
                                CircleAvatar(
                                  radius: 20, // Ukuran avatar disesuaikan
                                  backgroundColor: Colors.grey.shade300,
                                  backgroundImage: NetworkImage(
                                    _getAvatarUrl(user['username']),
                                  ),
                                  onBackgroundImageError: (e, s) {},
                                ),
                              ],
                            ),
                            title: Text(
                              user["username"] ?? "User",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15, // Sedikit dikecilkan
                                color: darkTextColor,
                              ),
                              maxLines: 1, // Pastikan tidak lebih dari 1 baris
                              overflow:
                                  TextOverflow
                                      .ellipsis, // Ellipsis jika terlalu panjang
                            ),
                            trailing: Text(
                              "${user["points"] ?? 0} Poin",
                              style: GoogleFonts.poppins(
                                fontSize: 13, // Sedikit dikecilkan
                                fontWeight: FontWeight.w500,
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

  Widget _buildTopUser(Map<String, dynamic> user, int rank, Color rankColor) {
    final double baseHeight = 100;
    final double heightFactor = rank == 1 ? 1.4 : (rank == 2 ? 1.15 : 1.0);

    // Define avatar radius based on rank directly for more control
    double currentAvatarRadius;
    if (rank == 1) {
      currentAvatarRadius = 25 * 1.3; // approx 32.5
    } else if (rank == 2) {
      currentAvatarRadius = 25 * 1.1; // approx 27.5
    } else {
      // Rank 3 (and any other, though layout is for top 3)
      currentAvatarRadius = 22; // Radius 22, Diameter 44 (was 25, Diameter 50)
    }

    // Define SizedBox heights based on rank
    double spaceAfterAvatar;
    double spaceAfterUsername;

    if (rank == 3) {
      spaceAfterAvatar = 4.0; // Reduced from 5
      spaceAfterUsername = 2.0; // Reduced from 3
    } else {
      spaceAfterAvatar = 5.0;
      spaceAfterUsername = 3.0;
    }

    final String username = user["username"] ?? "User";
    final int points = user["points"] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          Icon(Icons.emoji_events_rounded, color: rankColor, size: 30),
        if (rank == 1) const SizedBox(height: 3),
        Container(
          height: baseHeight * heightFactor,
          width: 90,
          padding: const EdgeInsets.symmetric(
            vertical: 8, // Total 16px vertical padding
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: rankColor, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(_getAvatarUrl(username)),
                radius: currentAvatarRadius, // Use adjusted radius
                backgroundColor: Colors.white.withOpacity(0.5),
                onBackgroundImageError: (e, s) {},
              ),
              SizedBox(height: spaceAfterAvatar), // Use adjusted spacing
              Text(
                username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: spaceAfterUsername), // Use adjusted spacing
              Text(
                "$points Poin",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "#$rank",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: rank == 1 ? Colors.black87 : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _getAvatarUrl(String name) {
    // ignore: unused_local_variable
    final hash = name.hashCode;
    return "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff&size=128&font-size=0.33"; // font-size ditambahkan agar inisial lebih kecil jika nama panjang
  }
}
