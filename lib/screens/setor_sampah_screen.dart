import 'package:flutter/material.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/services/api_service.dart';

class SetorSampahScreen extends StatefulWidget {
  const SetorSampahScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _SetorSampahScreenState createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  final _beratController = TextEditingController();
  Map<String, dynamic>? _selectedKategori;
  late Future<List<dynamic>> _kategoriFuture;

  // Style konsisten untuk input
  final InputDecoration _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20, // Tambah padding horizontal
      vertical: 18,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300), // Border lebih jelas
    ),
    enabledBorder: OutlineInputBorder(
      // Border saat enable
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      // Border saat fokus
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color.fromARGB(255, 7, 168, 13), width: 2),
    ),
    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500), // Hint style
  );

  @override
  void initState() {
    super.initState();
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

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            // Ganti WillPopScope dengan PopScope
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text("Memproses data..."),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final response = await ApiService.setorSampah(
        int.parse(userId!),
        _selectedKategori!['id'],
        beratGram,
      );

      Navigator.pop(context); // Tutup loading dialog

      if (response.containsKey('points_earned')) {
        await SharedPrefs.savePoin(totalPoinBaru);
        _showDialog(
          "Berhasil",
          "Setor $beratGram gram (${beratKg.toStringAsFixed(2)} $unit) $jenis.\n"
              "Kamu dapat ${response['points_earned']} poin!\n"
              "Total poin sekarang: $totalPoinBaru",
          isSuccess: true,
        );
        _beratController.clear();
        setState(() => _selectedKategori = null);
      } else {
        final msg =
            response['message'] ?? "Terjadi kesalahan saat setor sampah.";
        _showDialog("Gagal", msg);
      }
    } catch (e) {
      Navigator.pop(context); // Tutup loading dialog jika ada error
      _showDialog(
        "Error",
        "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.",
      );
    }
  }

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Radius lebih besar
            ),
            icon: Icon(
              // Tambahkan icon
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
              size: 48,
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center, // Tombol di tengah
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showKategoriDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparan untuk custom shape
      shape: const RoundedRectangleBorder(
        // Custom shape untuk bottom sheet
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          // Membuat sheet bisa di-drag
          initialChildSize: 0.6, // Ukuran awal
          minChildSize: 0.3, // Ukuran minimal
          maxChildSize: 0.9, // Ukuran maksimal
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle / Indikator drag
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8.0,
                    ),
                    child: Text(
                      "Pilih Kategori Sampah",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: _kategoriFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'Tidak ada kategori sampah',
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }
                        final kategoriList = snapshot.data!;
                        return ListView.builder(
                          controller:
                              scrollController, // Gunakan scrollController dari DraggableScrollableSheet
                          itemCount: kategoriList.length,
                          itemBuilder: (ctx, index) {
                            final kategori = kategoriList[index];
                            final bool isSelected =
                                _selectedKategori != null &&
                                _selectedKategori!['id'] == kategori['id'];
                            return Material(
                              // Tambahkan Material untuk InkWell
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedKategori = kategori;
                                  });
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ), // Kurangi margin vertical
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.white,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.green
                                              : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        // Agar teks tidak overflow
                                        child: Text(
                                          kategori['name'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color:
                                                isSelected
                                                    ? Colors.green.shade700
                                                    : Colors.black87,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                        )
                                      else
                                        Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.grey.shade400,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background lebih cerah sedikit
      appBar: AppBar(
        title: Text(
          "Setor Sampah",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color.fromARGB(
          255,
          7,
          168,
          13,
        ), // Warna hijau lebih modern
        foregroundColor: Colors.white, // Warna ikon dan teks tombol kembali
        elevation: 2, // Sedikit shadow
        shape: const RoundedRectangleBorder(
          // AppBar dengan sudut bawah melengkung
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20), // Padding konsisten
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pilih Jenis Sampah",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Sedikit lebih bold
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showKategoriDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, // Samakan dengan input decoration
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      // Shadow halus
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // Agar teks tidak overflow
                        child: Text(
                          _selectedKategori == null
                              ? 'Ketuk untuk memilih...'
                              : _selectedKategori!['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color:
                                _selectedKategori == null
                                    ? Colors
                                        .grey
                                        .shade600 // Warna hint
                                    : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.grey.shade700,
                        size: 28,
                      ), // Icon lebih besar
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24), // Spasi antar field
              Text(
                "Berat Sampah",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _beratController,
                keyboardType: TextInputType.number, // Hanya angka
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                ), // Style teks input
                decoration: _inputDecoration.copyWith(
                  // Gunakan style konsisten
                  hintText: "Contoh: 500",
                  prefixIcon: Icon(
                    Icons.scale_outlined,
                    color: Colors.green.shade600,
                  ), // Icon prefix
                  suffixText: "gram", // Tambahkan unit
                  suffixStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 32), // Spasi lebih besar sebelum tombol
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    // Tombol dengan icon
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      "Setor Sekarang",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500, // Warna tombol
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3, // Shadow tombol
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Padding bawah
            ],
          ),
        ),
      ),
    );
  }
}
