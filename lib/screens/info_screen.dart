import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Info Pengelolaan Sampah",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Mengapa Pengelolaan Sampah Penting?",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Pengelolaan sampah membantu menjaga kebersihan lingkungan, mengurangi pencemaran, dan memaksimalkan daur ulang bahan-bahan yang masih bisa digunakan.",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              SizedBox(height: 24),

              Text(
                "Jenis-Jenis Sampah:",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              // List jenis sampah dengan ikon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco, color: Colors.green[700], size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Sampah Organik: sisa makanan, daun kering",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.delete_outline, color: Colors.blue[700], size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Sampah Anorganik: plastik, kaleng, kertas",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.red[700],
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Sampah B3: baterai bekas, elektronik rusak",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              Text(
                "Tips Mengelola Sampah:",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              // Tips dengan bullet list icon
              _buildTip("Pisahkan sampah berdasarkan jenisnya"),
              _buildTip("Gunakan kembali barang yang masih bisa dipakai"),
              _buildTip("Daur ulang jika memungkinkan"),
              _buildTip("Buang sampah pada tempatnya"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }
}
