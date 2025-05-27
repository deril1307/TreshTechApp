import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class KategoriDetailScreen extends StatelessWidget {
  final dynamic kategori;

  // Definisikan warna utama untuk konsistensi
  final Color primaryColor = const Color.fromARGB(255, 7, 168, 13);
  final Color lightScreenBackground = const Color(
    0xFFF0F4F8,
  ); // Warna background netral
  final Color darkTextColor = Colors.black87; // Ini adalah const
  final Color lightTextColor = Colors.black54; // Ini adalah const
  // PERBAIKAN: Menggunakan Color.fromARGB untuk membuat nilai konstan
  final Color cardShadowColor = const Color.fromARGB(
    20,
    0,
    0,
    0,
  ); // sebelumnya: Colors.black.withOpacity(0.08)

  const KategoriDetailScreen({super.key, required this.kategori});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = kategori['cloudinary_url'];
    final String defaultImage =
        "assets/images/default_image.png"; // Pastikan path ini benar

    return Scaffold(
      backgroundColor: lightScreenBackground,
      appBar: AppBar(
        title: Text(
          kategori['name'] ?? 'Detail Kategori',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Hero(
                tag: imageUrl,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: MediaQuery.of(context).size.width,
                  height: 280,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        width: MediaQuery.of(context).size.width,
                        height: 280,
                        color: Colors.grey.shade300,
                        child: Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Image.asset(
                        defaultImage,
                        width: MediaQuery.of(context).size.width,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                ),
              )
            else
              Image.asset(
                defaultImage,
                width: MediaQuery.of(context).size.width,
                height: 280,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kategori['name'] ?? 'Nama Kategori',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: darkTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.orange.shade600,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            "Poin: ${kategori['point_per_unit']} / ${kategori['unit']}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 30,
                    thickness: 1,
                    color: Colors.black12,
                  ),
                  Text(
                    "Deskripsi Kategori",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    kategori['description'] ??
                        'Tidak ada deskripsi untuk kategori ini.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: lightTextColor,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
