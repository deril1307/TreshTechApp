import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends StatelessWidget {
  // Definisikan warna utama untuk konsistensi dan kemudahan modifikasi
  final Color primaryColor = const Color.fromARGB(255, 7, 168, 13);
  final Color lightGreenBackground = Colors.green.shade50;
  final Color darkGreenText = Colors.green.shade800; // Untuk judul dalam kartu
  final Color bodyTextColor = Colors.black.withOpacity(0.75);
  final Color cardShadowColor = Colors.black.withOpacity(0.06);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenBackground,
      appBar: AppBar(
        title: Text(
          "Info Pengelolaan Sampah",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white, // Pastikan teks AppBar putih
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 1.0, // Elevasi AppBar yang halus
      ),
      body: SingleChildScrollView(
        // Scroll default adalah vertikal
        physics: const BouncingScrollPhysics(), // Efek scroll yang lebih modern
        // Padding untuk seluruh konten yang bisa di-scroll
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          // Kartu akan mengambil lebar penuh (dikurangi padding horizontal)
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(
              context,
              title: "Mengapa Pengelolaan Sampah Penting?",
              content:
                  "Pengelolaan sampah membantu menjaga kebersihan lingkungan, mengurangi pencemaran, dan memaksimalkan daur ulang bahan-bahan yang masih bisa digunakan.",
            ),
            // Memberi jarak antar kartu secara vertikal
            const SizedBox(height: 20),
            _buildJenisSampahCard(context),
            const SizedBox(height: 20),
            _buildTipsCard(context),
            const SizedBox(
              height: 20,
            ), // Sedikit padding di bagian bawah scroll
          ],
        ),
      ),
    );
  }

  // Helper untuk judul kartu dengan ikon
  Widget _buildCardTitleWithIcon(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize:
                  17, // Sedikit lebih kecil dari 18 agar tidak terlalu dominan
              fontWeight: FontWeight.bold,
              color: darkGreenText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Container(
      // width: MediaQuery.of(context).size.width * 0.8, // Dihapus, lebar akan menyesuaikan parent (Column)
      padding: const EdgeInsets.all(18), // Padding internal kartu
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Radius lebih modern
        boxShadow: [
          BoxShadow(
            blurRadius: 10, // Blur lebih halus
            color: cardShadowColor,
            offset: const Offset(0, 3), // Sedikit offset Y untuk shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Kartu menyesuaikan tinggi konten
        children: [
          _buildCardTitleWithIcon(
            title,
            Icons.eco_rounded,
          ), // Menggunakan helper judul
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: bodyTextColor,
              height: 1.5, // Jarak antar baris untuk readability
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisSampahCard(BuildContext context) {
    return Container(
      // width: MediaQuery.of(context).size.width * 0.8, // Dihapus
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: cardShadowColor,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitleWithIcon(
            "Jenis-Jenis Sampah Umum",
            Icons.category_rounded,
          ),
          const SizedBox(height: 16), // Spasi lebih besar sebelum list
          _buildJenisItem(
            Icons.restaurant_menu_rounded, // Ikon lebih spesifik
            "Sampah Organik",
            "Contoh: Sisa makanan, kulit buah, sayuran, daun kering.",
            Colors.green.shade600,
          ),
          const SizedBox(height: 12),
          _buildJenisItem(
            Icons.inventory_2_outlined, // Ikon untuk barang/kemasan
            "Sampah Anorganik",
            "Contoh: Plastik, botol, kaleng, kertas, kaca.",
            Colors.blue.shade600,
          ),
          const SizedBox(height: 12),
          _buildJenisItem(
            Icons.warning_amber_rounded, // Ikon B3
            "Sampah B3 (Berbahaya & Beracun)",
            "Contoh: Baterai bekas, lampu neon, elektronik rusak, pestisida.",
            Colors.red.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildJenisItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
      ), // Padding untuk setiap item
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align ke atas jika teks panjang
        children: [
          CircleAvatar(
            radius: 18, // Ukuran avatar disesuaikan
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ), // Ukuran ikon dalam avatar
          ),
          const SizedBox(width: 12), // Jarak antara ikon dan teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // Judul item lebih tebal
                    color: darkGreenText.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: bodyTextColor.withOpacity(0.8),
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
    return Container(
      // width: MediaQuery.of(context).size.width * 0.8, // Dihapus
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: cardShadowColor,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardTitleWithIcon(
            "Tips Praktis Mengelola Sampah",
            Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildTip(
            "Pisahkan sampah berdasarkan jenisnya (organik, anorganik, B3).",
          ),
          _buildTip(
            "Gunakan kembali (reuse) barang-barang yang masih layak pakai.",
          ),
          _buildTip(
            "Daur ulang (recycle) sampah anorganik menjadi produk baru.",
          ),
          _buildTip("Olah sampah organik menjadi kompos untuk pupuk tanaman."),
          _buildTip("Kurangi penggunaan produk sekali pakai (reduce)."),
          _buildTip("Selalu buang sampah pada tempat yang telah disediakan."),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0), // Spasi antar tips
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: primaryColor,
            size: 20,
          ), // Ukuran ikon
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: bodyTextColor,
                height: 1.4, // Jarak antar baris
              ),
            ),
          ),
        ],
      ),
    );
  }
}
