import 'package:flutter/material.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kategori_sampah_screen.dart';

class SetorSampahScreen extends StatefulWidget {
  @override
  _SetorSampahScreenState createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  final _beratController = TextEditingController();
  Map<String, dynamic>? _selectedKategori;

  void _submitData() async {
    final beratGram = double.tryParse(_beratController.text) ?? 0;

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
    final totalPoinLama = SharedPrefs.getPoin();
    final totalPoinBaru = totalPoinLama + poinDidapat;

    await SharedPrefs.savePoin(totalPoinBaru);

    _showDialog(
      "Berhasil",
      "Setor $beratGram gram (${beratKg.toStringAsFixed(2)} $unit) $jenis.\n"
          "Kamu dapat $poinDidapat poin!\n"
          "Total poin sekarang: $totalPoinBaru",
    );

    _beratController.clear();
    setState(() {
      _selectedKategori = null;
    });
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

  void _pilihKategori() async {
    final hasil = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KategoriSampahScreen()),
    );

    if (hasil != null && hasil is Map<String, dynamic>) {
      setState(() {
        _selectedKategori = hasil;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Setor Sampah", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
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
              GestureDetector(
                onTap: _pilihKategori,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
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
                        _selectedKategori != null
                            ? _selectedKategori!['name']
                            : "Pilih Jenis Sampah",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                    ],
                  ),
                ),
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
