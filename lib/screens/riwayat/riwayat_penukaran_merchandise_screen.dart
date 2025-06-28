import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';

// Model sederhana untuk data penukaran
class RiwayatPenukaran {
  final String namaMerchandise;
  final String status;
  final String imageUrl;
  final DateTime tanggal;
  final int poin;

  RiwayatPenukaran({
    required this.namaMerchandise,
    required this.status,
    required this.imageUrl,
    required this.tanggal,
    required this.poin,
  });

  factory RiwayatPenukaran.fromJson(Map<String, dynamic> json) {
    return RiwayatPenukaran(
      namaMerchandise: json['merchandise_name'] ?? 'Nama Barang Tidak Ada',
      status: json['status'] ?? 'UNKNOWN',
      imageUrl: json['image_url'] ?? '',
      tanggal:
          DateTime.tryParse(json['redemption_date'] ?? '') ?? DateTime.now(),
      poin: int.tryParse(json['points_spent'].toString()) ?? 0,
    );
  }
}

class RiwayatPenukaranScreen extends StatefulWidget {
  const RiwayatPenukaranScreen({Key? key}) : super(key: key);

  @override
  State<RiwayatPenukaranScreen> createState() => _RiwayatPenukaranScreenState();
}

class _RiwayatPenukaranScreenState extends State<RiwayatPenukaranScreen> {
  late Future<List<RiwayatPenukaran>> _futureRiwayat;

  @override
  void initState() {
    super.initState();
    _futureRiwayat = _loadRiwayat();
  }

  Future<List<RiwayatPenukaran>> _loadRiwayat() async {
    String? userId = await SharedPrefs.getUserId();
    if (userId == null) {
      // Jika user tidak login, lemparkan error yang akan ditangkap FutureBuilder
      throw Exception('User tidak ditemukan. Silakan login kembali.');
    }

    // Memanggil API service untuk mendapatkan data riwayat
    final List<Map<String, dynamic>> riwayatJson =
        await ApiService.getRiwayatPenukaran(userId);

    // Mengubah list JSON menjadi list object RiwayatPenukaran
    return riwayatJson.map((json) => RiwayatPenukaran.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Riwayat Penukaran")),
      body: FutureBuilder<List<RiwayatPenukaran>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Menampilkan pesan error yang lebih informatif
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Gagal memuat data:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Anda belum pernah menukar merchandise.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ),
            );
          }

          final riwayatList = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureRiwayat = _loadRiwayat();
              });
            },
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: riwayatList.length,
              itemBuilder: (context, index) {
                final item = riwayatList[index];
                return _buildRiwayatCard(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiwayatCard(BuildContext context, RiwayatPenukaran item) {
    final bool isWaiting = item.status.toUpperCase() == 'MENUNGGU';
    final Color statusColor =
        isWaiting ? Colors.orange.shade700 : Colors.green.shade700;
    final String statusText = isWaiting ? "Menunggu" : "Selesai";

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade400,
                      ),
                    ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaMerchandise,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${item.poin} Poin',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'dd MMMM yyyy, HH:mm',
                      'id_ID',
                    ).format(item.tanggal),
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Chip(
              label: Text(
                statusText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              backgroundColor: statusColor,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ],
        ),
      ),
    );
  }
}
