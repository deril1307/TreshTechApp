import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart'; // Pastikan path ini benar
import 'package:google_fonts/google_fonts.dart';
// ignore: unused_import
import 'package:tubes_mobile/services/api_service.dart'; // Pastikan path ini benar

class TarikSaldoScreen extends StatefulWidget {
  @override
  _TarikSaldoScreenState createState() => _TarikSaldoScreenState();
}

class _TarikSaldoScreenState extends State<TarikSaldoScreen> {
  String? _selectedAmount;

  final List<String> _amountOptions = [
    '50.000',
    '100.000',
    '200.000',
    '500.000',
    '1.000.000',
  ];

  double saldo = 0.0; // Akan di-update oleh _loadUserData
  // int poin = 0; // poin tidak digunakan di screen ini berdasarkan kode Anda

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- LOGIKA BACKEND ANDA (TIDAK DIUBAH) ---
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Pastikan icon ada

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showUINotification(String title, String body) async {
    // Renamed to avoid conflict
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'tarik_saldo_channel',
          'Tarik Saldo Notifications',
          channelDescription: 'Notifikasi untuk transaksi tarik saldo',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  Future<void> _loadUserData() async {
    double savedSaldo = await SharedPrefs.getSaldo();
    // int savedPoin = await SharedPrefs.getPoin(); // poin tidak digunakan di UI ini
    if (mounted) {
      setState(() {
        saldo = savedSaldo;
        // poin = savedPoin;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      // Pertimbangkan untuk menampilkan dialog yang mengarahkan pengguna ke pengaturan aplikasi
      openAppSettings();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initNotifications();
    _requestNotificationPermission();
  }

  void _tarikSaldo() async {
    if (_selectedAmount == null) {
      _showCustomSnackbar(
        'Harap pilih jumlah saldo terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final jumlahTarik = double.tryParse(
      _selectedAmount!.replaceAll('.', '').replaceAll('Rp ', ''),
    );

    if (jumlahTarik == null) {
      _showCustomSnackbar('Jumlah saldo tidak valid.', isError: true);
      return;
    }

    // Anda mungkin perlu membuat SharedPrefs.getUserId() menjadi async jika belum
    // Untuk contoh ini, saya asumsikan sinkron berdasarkan kode asli
    final userId = SharedPrefs.getUserId();

    if (userId == null) {
      _showCustomSnackbar(
        'User ID tidak ditemukan. Mohon login ulang.',
        isError: true,
      );
      return;
    }

    // Cek apakah saldo mencukupi
    if (saldo < jumlahTarik) {
      _showCustomSnackbar(
        'Saldo Anda tidak mencukupi untuk melakukan penarikan ini.',
        isError: true,
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    bool? confirm = await _showConfirmationDialog(
      title: "Konfirmasi Penarikan",
      content: "Anda yakin ingin menarik saldo sebesar Rp$_selectedAmount?",
      confirmText: "Ya, Tarik",
      cancelText: "Batal",
    );

    if (confirm != true) {
      return; // Pengguna membatalkan
    }

    try {
      // Tampilkan loading indicator jika perlu
      // Misalnya: showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));

      final result = await ApiService.tarikSaldo(
        userId:
            userId, // Pastikan userId adalah string jika diperlukan ApiService
        amount: jumlahTarik,
      );

      // Navigator.pop(context); // Tutup loading indicator

      if (result['status'] == 'success') {
        if (mounted) {
          setState(() {
            // Asumsikan API mengembalikan 'new_balance' sebagai double atau int
            var newBalance = result['new_balance'];
            if (newBalance is int) {
              saldo = newBalance.toDouble();
            } else if (newBalance is double) {
              saldo = newBalance;
            } else if (newBalance is String) {
              saldo = double.tryParse(newBalance) ?? saldo;
            }
            _selectedAmount = null; // Reset pilihan
          });
        }

        await SharedPrefs.saveSaldo(saldo);

        final formattedAmount = jumlahTarik
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            );

        final successMessage =
            'Permintaan tarik saldo sebesar Rp $formattedAmount telah dikirim.';

        await _showUINotification('Tarik Saldo Berhasil', successMessage);

        await SharedPrefs.tambahRiwayat({
          'kegiatan': 'Penarikan Saldo',
          'jenis': 'Tarik Saldo',
          'tanggal': DateTime.now().toIso8601String(),
          'saldo': "Rp $formattedAmount", // Simpan dengan format
        });

        _showCustomSnackbar(successMessage);
      } else {
        _showCustomSnackbar(
          result['message'] ?? 'Gagal melakukan penarikan saldo.',
          isError: true,
        );
      }
    } catch (e) {
      // Navigator.pop(context); // Tutup loading indicator jika masih ada
      _showCustomSnackbar(
        'Terjadi kesalahan jaringan atau server: ${e.toString()}',
        isError: true,
      );
    }
  }
  // --- AKHIR LOGIKA BACKEND ANDA ---

  // --- BAGIAN TAMPILAN (UI) YANG DIPERBARUI ---

  // Snackbar kustom yang lebih sesuai tema
  void _showCustomSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            isError
                ? Colors.red.shade600
                : const Color.fromARGB(
                  255,
                  18,
                  148,
                  25,
                ), // Warna tema utama untuk sukses
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
      ),
    );
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 7, 168, 13),
              ),
            ),
            content: Text(content, style: GoogleFonts.poppins(fontSize: 15)),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              if (cancelText != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    cancelText,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(
                    255,
                    7,
                    168,
                    13,
                  ), // Warna tema
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color.fromARGB(255, 7, 168, 13);
    final Color lightGreenBg = const Color.fromARGB(
      255,
      230,
      245,
      231,
    ); // Warna background lembut

    final formattedSaldo = saldo
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      backgroundColor: Colors.white, // Background utama layar
      appBar: AppBar(
        title: Text(
          "Tarik Saldo",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryGreen,
        elevation: 1.0, // Sedikit shadow
      ),
      body: SingleChildScrollView(
        // Agar bisa di-scroll jika konten panjang
        padding: const EdgeInsets.all(20.0), // Padding menyeluruh
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Info Saldo
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: lightGreenBg, // Background hijau muda untuk kartu
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: primaryGreen,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    // Expanded agar teks tidak overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Saldo Anda Saat Ini",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: primaryGreen.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rp $formattedSaldo",
                          style: GoogleFonts.poppins(
                            fontSize: 26, // Ukuran font saldo lebih besar
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Judul Pilihan Jumlah
            Text(
              "Pilih Jumlah Penarikan",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown Pilihan Jumlah
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ), // Padding dalam dropdown
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ), // Border lebih tebal dan lembut
                borderRadius: BorderRadius.circular(
                  12.0,
                ), // Border radius lebih besar
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAmount,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: primaryGreen,
                    size: 28,
                  ), // Icon dropdown
                  hint: Text(
                    "Pilih nominal",
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                  items:
                      _amountOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            'Rp $value',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedAmount = newValue);
                  },
                  dropdownColor: Colors.white, // Warna background item dropdown
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedAmount != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Anda akan menarik: Rp$_selectedAmount",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // Tombol Aksi
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ), // Icon dengan warna putih
                label: Text(
                  "Tarik Saldo Sekarang",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: _tarikSaldo, // Memanggil fungsi _tarikSaldo Anda
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, // Warna tombol konsisten
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ), // Padding tombol
                  minimumSize: const Size(
                    double.infinity,
                    50,
                  ), // Tombol full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ), // Border radius tombol
                  ),
                  elevation: 4, // Shadow tombol
                ),
              ),
            ),
            const SizedBox(height: 20), // Jarak tambahan di bawah tombol
          ],
        ),
      ),
    );
  }
}
