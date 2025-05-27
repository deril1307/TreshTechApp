import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'package:tubes_mobile/utils/shared_prefs.dart'; // Pastikan ini adalah utilitas Shared Preferences Anda
import 'package:tubes_mobile/services/api_service.dart';
import 'kategori_detail_screen.dart';

class KategoriSampahScreen extends StatefulWidget {
  const KategoriSampahScreen({super.key});

  @override
  _KategoriSampahScreenState createState() => _KategoriSampahScreenState();
}

class _KategoriSampahScreenState extends State<KategoriSampahScreen> {
  List<dynamic> categories = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  // Definisikan warna tema untuk konsistensi
  final Color primaryColor = const Color.fromARGB(255, 7, 168, 13);
  final Color lightGreenBackground = Colors.green.shade50;
  final Color cardShadowColor = Colors.black.withOpacity(0.08);

  @override
  void initState() {
    super.initState();
    _loadCachedDataThenFetch();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (mounted) await _checkInternetAndFetchData();
    });
  }

  Future<void> _loadCachedDataThenFetch() async {
    // Menggunakan SharedPrefUtils sesuai kode asli Anda
    String? cachedData = await SharedPrefUtils.getKategoriSampah();
    if (cachedData != null) {
      if (mounted) {
        setState(() {
          categories = jsonDecode(cachedData);
          isLoading =
              categories
                  .isEmpty; // Jika cache ada tapi kosong, tetap loading sampai fetch
        });
      }
    }
    // Selalu coba fetch data terbaru setelah memuat cache (atau jika cache tidak ada)
    await _checkInternetAndFetchData();
  }

  Future<void> _checkInternetAndFetchData() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    // Periksa apakah ada konektivitas selain none
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet)) {
      await fetchCategories();
    } else {
      // Jika tidak ada internet dan tidak ada cache (atau cache kosong)
      if (categories.isEmpty && mounted) {
        setState(() {
          isLoading = false; // Berhenti loading, tampilkan pesan empty state
        });
      }
    }
  }

  Future<void> fetchCategories() async {
    if (!mounted) return; // Hindari setState jika widget sudah di-dispose
    // Jika belum loading, set isLoading true sebelum fetch
    if (!isLoading && categories.isEmpty) {
      // Hanya set true jika memang belum ada data
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await ApiService.getKategoriSampah();
      await SharedPrefUtils.setKategoriSampah(jsonEncode(data));

      if (mounted) {
        setState(() {
          categories = data;
        });
      }
    } catch (e) {
      print("Gagal mengambil kategori: $e");
      // Di sini Anda bisa menampilkan Snackbar atau pesan error jika diperlukan
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    // Set isLoading true saat memulai refresh untuk menampilkan indicator
    // jika diinginkan, atau biarkan RefreshIndicator yang handle visualnya.
    await _checkInternetAndFetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenBackground, // Background lebih lembut
      appBar: AppBar(
        title: Text(
          'Kategori Sampah',
          style: GoogleFonts.poppins(
            // Menggunakan GoogleFonts
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 1.0, // Elevasi AppBar yang halus
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : categories.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Belum ada kategori sampah.",
                        style: GoogleFonts.poppins(
                          // Menggunakan GoogleFonts
                          fontSize: 17,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Silakan cek kembali nanti atau coba refresh halaman.",
                        style: GoogleFonts.poppins(
                          // Menggunakan GoogleFonts
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          "Refresh",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _refreshData,
                color: primaryColor, // Warna indikator refresh
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ), // Padding list
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final String? imageUrl = category['cloudinary_url'];
                    final String defaultImage =
                        "assets/images/default_image.png"; // Pastikan path ini benar

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => KategoriDetailScreen(kategori: category),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // Radius lebih besar
                        ),
                        elevation: 3, // Elevasi lebih halus
                        shadowColor: cardShadowColor,
                        margin: const EdgeInsets.only(
                          bottom: 16,
                        ), // Jarak antar kartu
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nomor urut dengan style
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Gambar Kategori
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Radius gambar
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl ?? "",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: Colors.grey.shade400,
                                          size: 40,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Image.asset(
                                        defaultImage, // Gambar default jika error
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Detail Kategori
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category['name'] ?? 'Tanpa Nama',
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight.w600, // Lebih tebal
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Poin: ${category['point_per_unit']} / ${category['unit']}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: primaryColor, // Warna poin
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      category['description'] ??
                                          'Tidak ada deskripsi.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        height: 1.4, // Jarak antar baris
                                      ),
                                      maxLines: 2, // Batasi deskripsi
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Icon panah untuk indikasi bisa diklik
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.grey.shade400,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
