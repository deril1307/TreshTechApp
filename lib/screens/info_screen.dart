// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class InfoScreen extends StatelessWidget {
  // Tambahkan constructor dengan key
  InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final customColors = theme.extension<CustomThemeColors>()!;
    // ignore: unused_local_variable
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Gunakan warna dari tema
      appBar: AppBar(
        title: Text(
          "Info Pengelolaan Sampah",
          // Style sudah diatur oleh AppBarTheme di main.dart
        ),
        // backgroundColor dan iconTheme juga dari AppBarTheme
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              context, // Pass context
              title: "Mengapa Pengelolaan Sampah Penting?",
              content:
                  "Pengelolaan sampah membantu menjaga kebersihan lingkungan, mengurangi pencemaran, dan memaksimalkan daur ulang bahan-bahan yang masih bisa digunakan.",
            ),
            const SizedBox(height: 20),
            _buildJenisSampahCard(context), // Pass context
            const SizedBox(height: 20),
            _buildTipsCard(context), // Pass context
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTitleWithIcon(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    return Row(
      children: [
        Icon(
          icon,
          color: theme.primaryColor,
          size: 26,
        ), // Gunakan primaryColor dari tema
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color:
                  customColors
                      .titleTextColor, // Gunakan titleTextColor dari tema
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, { // Tambahkan context
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor, // Gunakan cardColor dari tema
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: theme.shadowColor.withOpacity(
              0.06,
            ), // Gunakan shadowColor dari tema
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitleWithIcon(
            context,
            title,
            Icons.eco_rounded,
          ), // Pass context
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14.5, // Ukuran font disesuaikan agar lebih mudah dibaca
              color:
                  customColors.bodyTextColor, // Gunakan bodyTextColor dari tema
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisSampahCard(BuildContext context) {
    // Tambahkan context
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: theme.shadowColor.withOpacity(0.06),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitleWithIcon(
            context,
            "Jenis-Jenis Sampah Umum",
            Icons.category_rounded,
          ), // Pass context
          const SizedBox(height: 16),
          _buildJenisItem(
            context, // Pass context
            Icons.restaurant_menu_rounded,
            "Sampah Organik",
            "Contoh: Sisa makanan, kulit buah, sayuran, daun kering.",
            isDarkMode
                ? Colors.green.shade300
                : Colors.green.shade600, // Warna ikon disesuaikan mode
          ),
          const SizedBox(height: 12),
          _buildJenisItem(
            context, // Pass context
            Icons.inventory_2_outlined,
            "Sampah Anorganik",
            "Contoh: Plastik, botol, kaleng, kertas, kaca.",
            isDarkMode
                ? Colors.blue.shade300
                : Colors.blue.shade600, // Warna ikon disesuaikan mode
          ),
          const SizedBox(height: 12),
          _buildJenisItem(
            context, // Pass context
            Icons.warning_amber_rounded,
            "Sampah B3 (Berbahaya & Beracun)",
            "Contoh: Baterai bekas, lampu neon, elektronik rusak, pestisida.",
            isDarkMode
                ? Colors.red.shade300
                : Colors.red.shade600, // Warna ikon disesuaikan mode
          ),
        ],
      ),
    );
  }

  Widget _buildJenisItem(
    BuildContext context, // Tambahkan context
    IconData icon,
    String title,
    String subtitle,
    Color iconColor, // Warna ikon tetap spesifik untuk membedakan jenis sampah
  ) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Padding antar item
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20, // Ukuran avatar disesuaikan
            backgroundColor: iconColor.withOpacity(
              isDarkMode ? 0.25 : 0.12,
            ), // Background avatar disesuaikan mode
            child: Icon(
              icon,
              color: iconColor, // Warna ikon
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15, // Ukuran font disesuaikan
                    fontWeight: FontWeight.w600,
                    color: customColors.titleTextColor?.withOpacity(
                      0.95,
                    ), // Warna dari tema
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13, // Ukuran font disesuaikan
                    color: customColors.secondaryTextColor, // Warna dari tema
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    // Tambahkan context
    final theme = Theme.of(context);
    // customColors tidak digunakan secara langsung di sini, tapi di _buildTip melalui context
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: theme.shadowColor.withOpacity(0.06),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitleWithIcon(
            context,
            "Tips Praktis Mengelola Sampah",
            Icons.lightbulb_outline_rounded,
          ), // Pass context
          const SizedBox(height: 16),
          _buildTip(
            context,
            "Pisahkan sampah berdasarkan jenisnya (organik, anorganik, B3).",
          ), // Pass context
          _buildTip(
            context,
            "Gunakan kembali (reuse) barang-barang yang masih layak pakai.",
          ), // Pass context
          _buildTip(
            context,
            "Daur ulang (recycle) sampah anorganik menjadi produk baru.",
          ), // Pass context
          _buildTip(
            context,
            "Olah sampah organik menjadi kompos untuk pupuk tanaman.",
          ), // Pass context
          _buildTip(
            context,
            "Kurangi penggunaan produk sekali pakai (reduce).",
          ), // Pass context
          _buildTip(
            context,
            "Selalu buang sampah pada tempat yang telah disediakan.",
          ), // Pass context
        ],
      ),
    );
  }

  Widget _buildTip(BuildContext context, String text) {
    // Tambahkan context
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0), // Spasi antar tips
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: theme.primaryColor, // Gunakan primaryColor dari tema
            size: 22, // Ukuran ikon disesuaikan
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14.5, // Ukuran font disesuaikan
                color:
                    customColors
                        .bodyTextColor, // Gunakan bodyTextColor dari tema
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
