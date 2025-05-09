// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/services/api_service.dart'; // Import ApiService

class SetorSampahScreen extends StatefulWidget {
  @override
  _SetorSampahScreenState createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  final _beratController = TextEditingController();
  Map<String, dynamic>? _selectedKategori;
  late Future<List<dynamic>>
  _kategoriFuture; // Future untuk mendapatkan data kategori sampah

  @override
  void initState() {
    super.initState();
    // Memanggil API untuk mendapatkan kategori sampah
    _kategoriFuture = ApiService.getKategoriSampah();
  }

  void _submitData() async {
    final beratGram = int.tryParse(_beratController.text) ?? 0;

    if (_selectedKategori == null || beratGram <= 0) {
      _showDialog(
        "Input tidak valid",
        "Pilih jenis dan masukkan berat sampah dengan benar.",
      );
      return;
    }

    final jenis = _selectedKategori!['name'];
    final poinPerKg = _selectedKategori!['point_per_unit'];
    final unit = _selectedKategori!['unit'];
    final beratKg = beratGram / 1000;
    final poinDidapat = (beratKg * poinPerKg).round();
    final totalPoinLama = await SharedPrefs.getPoin();
    final totalPoinBaru = totalPoinLama + poinDidapat;

    final userId = await SharedPrefs.getUserId();

    // Kirim ke API
    final response = await ApiService.setorSampah(
      int.parse(userId!),
      _selectedKategori!['id'],
      beratGram,
    );

    // Debug print
    print('API response: $response');

    // Dianggap sukses jika terdapat 'points_earned'
    if (response.containsKey('points_earned')) {
      // Simpan total poin terbaru
      await SharedPrefs.savePoin(totalPoinBaru);

      _showDialog(
        "Berhasil",
        "Setor $beratGram gram (${beratKg.toStringAsFixed(2)} $unit) $jenis.\n"
            "Kamu dapat ${response['points_earned']} poin!\n"
            "Total poin sekarang: $totalPoinBaru",
      );
    } else {
      // Tampilkan error dari API jika ada
      final msg = response['message'] ?? "Terjadi kesalahan saat setor sampah.";
      _showDialog("Gagal", msg);
    }

    _beratController.clear();
    setState(() => _selectedKategori = null);
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Setor Sampah", style: GoogleFonts.poppins()),
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Jenis Sampah",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<dynamic>>(
                future: _kategoriFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Tidak ada kategori sampah'));
                  }

                  final kategoriList = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: kategoriList.length,
                    itemBuilder: (ctx, index) {
                      final kategori = kategoriList[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedKategori = kategori;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                kategori['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color:
                                    _selectedKategori == kategori
                                        ? Colors.green
                                        : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 25),
              Text(
                "Berat (gram)",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _beratController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: "Contoh: 500",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Setor Sekarang",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on Map<String, dynamic> {
  get body => null;
}
