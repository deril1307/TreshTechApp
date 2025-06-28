import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class KategoriDetailScreen extends StatelessWidget {
  final dynamic kategori;
  final Color primaryColor = const Color.fromARGB(255, 7, 168, 13);
  final Color lightScreenBackground = const Color(0xFFF0F4F8);
  final Color darkTextColor = Colors.black87;
  final Color lightTextColor = Colors.black54;
  final Color cardShadowColor = const Color.fromARGB(20, 0, 0, 0);
  const KategoriDetailScreen({super.key, required this.kategori});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = kategori['cloudinary_url'];
    final String defaultImage = "assets/images/default_image.png";

    return Scaffold(
      backgroundColor: lightScreenBackground,

      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          kategori['name'] ?? 'Detail Kategori',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 2.0,
                color: Colors.black45,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent, // Transparan
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
          shadows: [Shadow(blurRadius: 2.0, color: Colors.black45)],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(context, imageUrl, defaultImage),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KARTU INFORMASI POIN ---
                  _buildInfoCard(
                    icon: Icons.star_rounded,
                    iconColor: Colors.orange.shade600,
                    title: "Poin Dihargai",
                    content:
                        "${kategori['point_per_unit']} Poin / ${kategori['unit']}",
                    isContentBold: true,
                  ),
                  const SizedBox(height: 16),

                  // --- KARTU DESKRIPSI ---
                  _buildInfoCard(
                    icon: Icons.info_outline_rounded,
                    iconColor: Colors.blue.shade600,
                    title: "Deskripsi Kategori",
                    content:
                        kategori['description'] ??
                        'Tidak ada deskripsi untuk kategori ini.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk Header Gambar yang lebih modern
  Widget _buildImageHeader(
    BuildContext context,
    String? imageUrl,
    String defaultImage,
  ) {
    return Hero(
      tag:
          kategori['id'] ??
          UniqueKey().toString(), // Gunakan ID atau key unik untuk tag
      child: Container(
        height: 300,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          image: DecorationImage(
            image:
                (imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(imageUrl)
                        : AssetImage(defaultImage))
                    as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget template untuk Kartu Informasi
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    bool isContentBold = false,
  }) {
    return Card(
      elevation: 2,
      shadowColor: cardShadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkTextColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: isContentBold ? FontWeight.bold : FontWeight.normal,
                color: isContentBold ? primaryColor : lightTextColor,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
