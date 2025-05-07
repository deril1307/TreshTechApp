import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tubes_mobile/services/api_service.dart';

class KategoriSampahScreen extends StatefulWidget {
  @override
  _KategoriSampahScreenState createState() => _KategoriSampahScreenState();
}

class _KategoriSampahScreenState extends State<KategoriSampahScreen> {
  List<dynamic> categories = [];
  bool isLoading = true;
  bool isOffline = false;
  final String baseUrl = "http://10.0.2.2:5000";

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Memuat kategori dari SharedPreferences jika user offline
  Future<void> _loadCategories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cached_categories');

    if (cachedData != null) {
      setState(() {
        categories = jsonDecode(cachedData);
        isLoading = false;
      });
    }

    _checkInternetAndFetchData();
  }

  /// Cek koneksi internet sebelum mengambil data terbaru
  Future<void> _checkInternetAndFetchData() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // Tidak ada koneksi internet
      setState(() {
        isOffline = true;
      });
    } else {
      // Ada koneksi internet, ambil data dari API
      fetchCategories();
    }
  }

  /// Mengambil kategori dari API dan menyimpan ke SharedPreferences
  Future<void> fetchCategories() async {
    try {
      List<dynamic> data = await ApiService.getKategoriSampah();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_categories', jsonEncode(data));

      if (mounted) {
        setState(() {
          categories = data;
          isOffline = false;
        });
      }
    } catch (e) {
      print(" Error fetching categories: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kategori Sampah',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : categories.isEmpty
              ? Center(
                child: Text(
                  isOffline
                      ? "Tidak ada data tersimpan. Harap sambungkan ke internet."
                      : "Tidak ada kategori tersedia.",
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
              : RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final String? imageUrl = category['cloudinary_url'];
                    final String defaultImage =
                        "assets/images/default_image.png";

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context, category);
                        print("Kategori ${category['name']}");
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nomor urutan
                              Text(
                                "${index + 1}.",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Gambar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl ?? "",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Image.asset(
                                        defaultImage,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
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

                              // Detail Kategori
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Poin: ${category['point_per_unit']} / ${category['unit']}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      category['description'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
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
