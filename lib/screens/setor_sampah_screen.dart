import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kategori_sampah_screen.dart'; // import file kategori

class SetorSampahScreen extends StatefulWidget {
  @override
  _SetorSampahScreenState createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  final _beratController = TextEditingController();
  Map<String, dynamic>? _selectedKategori;

  void _submitData() {
    final berat = double.tryParse(_beratController.text) ?? 0;

    if (_selectedKategori == null || berat <= 0) {
      _showDialog(
        "Input tidak valid",
        "Pilih jenis dan masukkan berat sampah dengan benar.",
      );
      return;
    }

    final jenis = _selectedKategori!['name'];
    final poin = _selectedKategori!['point_per_unit'];
    final unit = _selectedKategori!['unit'];

    _showDialog("Berhasil", "Setor $berat $unit $jenis dengan poin $poin.");

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
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
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
      appBar: AppBar(
        title: Text("Setor Sampah", style: GoogleFonts.poppins()),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Jenis Sampah", style: GoogleFonts.poppins(fontSize: 16)),
            InkWell(
              onTap: _pilihKategori,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedKategori != null
                          ? _selectedKategori!['name']
                          : "Pilih Jenis Sampah",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text("Berat (kg)", style: GoogleFonts.poppins(fontSize: 16)),
            TextField(
              controller: _beratController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: "Contoh: 2.5"),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text("Setor", style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
