// ignore_for_file: library_private_types_in_public_api, await_only_futures, unused_import

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart'; // Pastikan ini adalah utilitas Shared Preferences Anda
import 'package:tubes_mobile/services/api_service.dart';
import 'kategori_detail_screen.dart';
// Import MyApp dan CustomThemeColors dari main.dart
import '../main.dart';

class KategoriSampahScreen extends StatefulWidget {
  const KategoriSampahScreen({super.key});

  @override
  _KategoriSampahScreenState createState() => _KategoriSampahScreenState();
}

class _KategoriSampahScreenState extends State<KategoriSampahScreen> {
  List<dynamic> categories = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  @override
  void initState() {
    super.initState();
    _loadCachedDataThenFetch();
    _startAutoRefresh();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (mounted &&
          !isLoading &&
          (result.contains(ConnectivityResult.mobile) ||
              result.contains(ConnectivityResult.wifi) ||
              result.contains(ConnectivityResult.ethernet))) {
        _checkInternetAndFetchData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (mounted) await _checkInternetAndFetchData();
    });
  }

  Future<void> _loadCachedDataThenFetch() async {
    if (!mounted) return;
    // Set isLoading true di awal jika categories masih kosong
    if (categories.isEmpty) {
      setState(() {
        isLoading = true;
      });
    }

    String? cachedData = await SharedPrefUtils.getKategoriSampah();
    if (cachedData != null) {
      try {
        final decodedData = jsonDecode(cachedData);
        if (decodedData is List) {
          // Pastikan data yang di-decode adalah List
          if (mounted) {
            setState(() {
              categories = decodedData;
              // isLoading akan di-set false setelah fetch atau jika fetch gagal dan cache ada
            });
          }
        } else {
          print("Cached data for kategori sampah is not a List.");
        }
      } catch (e) {
        print("Error decoding cached kategori sampah: $e");
        // Jika ada error decoding, anggap cache tidak valid
        if (mounted) {
          setState(() {
            categories = [];
          });
        }
      }
    }
    // Selalu coba fetch data terbaru setelah memuat cache (atau jika cache tidak ada)
    await _checkInternetAndFetchData();
  }

  Future<void> _checkInternetAndFetchData() async {
    if (!mounted) return;
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      await fetchCategories();
    } else {
      // Jika tidak ada internet dan tidak ada cache (atau cache kosong)
      if (categories.isEmpty && mounted) {
        setState(() {
          isLoading = false; // Berhenti loading, tampilkan pesan empty state
        });
      } else if (mounted) {
        // Jika offline tapi ada data dari cache, pastikan isLoading false
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchCategories() async {
    if (!mounted) return;
    // Hanya set isLoading true jika memang belum ada data dan belum dalam proses loading
    if (categories.isEmpty && !isLoading) {
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
      // Jika fetch gagal tapi ada data cache, biarkan data cache ditampilkan
      // isLoading akan di-set false di finally
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    // Tidak perlu setState isLoading = true di sini secara eksplisit jika RefreshIndicator sudah menangani UI
    await _checkInternetAndFetchData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Kategori Sampah',
          // Style dari AppBarTheme di main.dart
        ),
        // backgroundColor, iconTheme, titleTextStyle dari AppBarTheme
        elevation: 1.0,
      ),
      body:
          isLoading &&
                  categories
                      .isEmpty // Tampilkan loading hanya jika data benar-benar kosong dan sedang loading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : categories.isEmpty &&
                  !isLoading // Tampilkan empty state jika data kosong setelah loading selesai
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        size: 80,
                        color: theme.hintColor.withOpacity(
                          0.7,
                        ), // Warna ikon dari tema
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Belum ada kategori sampah.",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          color:
                              customColors
                                  .secondaryTextColor, // Warna teks dari tema
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Silakan cek kembali nanti atau coba refresh halaman.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.hintColor, // Warna teks dari tema
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.refresh,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          "Refresh",
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.primaryColor, // Warna tombol dari tema
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
              )
              : RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.primaryColor,
                backgroundColor: theme.cardColor,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
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
                            // KategoriDetailScreen juga perlu diadaptasi untuk tema
                          ),
                        );
                      },
                      child: Card(
                        color:
                            theme.cardColor, // Warna background kartu dari tema
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: theme.shadowColor.withOpacity(
                          isDarkMode ? 0.15 : 0.08,
                        ), // Warna shadow dari tema
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .center, // Align vertikal ke tengah
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(
                                    isDarkMode ? 0.2 : 0.1,
                                  ), // Background nomor
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.primaryColorDark, // Warna nomor
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl ?? "",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        width: 80,
                                        height: 80,
                                        color: theme.dividerColor.withOpacity(
                                          0.1,
                                        ), // Warna placeholder
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: theme.hintColor.withOpacity(
                                            0.5,
                                          ), // Warna ikon placeholder
                                          size: 40,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Image.asset(
                                        defaultImage,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center, // Align teks ke tengah
                                  children: [
                                    Text(
                                      category['name'] ?? 'Tanpa Nama',
                                      style: GoogleFonts.poppins(
                                        fontSize:
                                            17.5, // Ukuran font disesuaikan
                                        fontWeight: FontWeight.w600,
                                        color:
                                            customColors
                                                .titleTextColor, // Warna dari tema
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Poin: ${category['point_per_unit']} / ${category['unit']}",
                                      style: GoogleFonts.poppins(
                                        fontSize:
                                            14.5, // Ukuran font disesuaikan
                                        fontWeight: FontWeight.w500,
                                        color:
                                            theme
                                                .primaryColor, // Warna poin dari tema
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      category['description'] ??
                                          'Tidak ada deskripsi.',
                                      style: GoogleFonts.poppins(
                                        fontSize:
                                            13.5, // Ukuran font disesuaikan
                                        color:
                                            customColors
                                                .secondaryTextColor, // Warna dari tema
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color:
                                    theme
                                        .hintColor, // Warna ikon panah dari tema
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
