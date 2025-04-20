import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiwayatScreen extends StatelessWidget {
  final List<Map<String, String>> riwayat = [
    {
      'tanggal': '19 April 2025',
      'kegiatan': 'Menukar 500 poin dengan Rp 50.000',
      'jenis': 'Penukaran',
    },
    {
      'tanggal': '17 April 2025',
      'kegiatan': 'Mengelompokkan sampah metal: Kaleng Bekas',
      'jenis': 'Sampah Metal',
    },
    {
      'tanggal': '15 April 2025',
      'kegiatan': 'Mengelompokkan sampah non-metal: Plastik',
      'jenis': 'Sampah Non-Metal',
    },
    {
      'tanggal': '10 April 2025',
      'kegiatan': 'Menarik saldo Rp 100.000',
      'jenis': 'Tarik Saldo',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Aktivitas", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: riwayat.length,
        itemBuilder: (context, index) {
          final item = riwayat[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                item['kegiatan']!,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              subtitle: Text(
                item['tanggal']!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              leading: Icon(
                item['jenis'] == 'Sampah Metal'
                    ? Icons.auto_awesome
                    : item['jenis'] == 'Sampah Non-Metal'
                    ? Icons.recycling
                    : Icons.attach_money,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }
}
