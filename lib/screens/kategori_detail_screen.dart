import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KategoriDetailScreen extends StatelessWidget {
  final dynamic kategori;

  const KategoriDetailScreen({super.key, required this.kategori});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = kategori['cloudinary_url'];
    final String defaultImage = "assets/images/default_image.png";

    return Scaffold(
      appBar: AppBar(
        title: Text(kategori['name'] ?? 'Detail Kategori'),
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar kategori
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? "",
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Image.asset(
                        defaultImage,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                  errorWidget:
                      (context, url, error) => Image.asset(
                        defaultImage,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nama Kategori
            Text(
              kategori['name'] ?? 'Nama Kategori',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24, thickness: 2),

            // Deskripsi
            Text(
              kategori['description'] ?? 'Tidak ada deskripsi tersedia.',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),

            // Informasi Poin
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  "Poin per unit: ${kategori['point_per_unit']} / ${kategori['unit']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
