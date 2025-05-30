import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart'; // Pastikan path ini benar
import 'package:tubes_mobile/services/api_service.dart'; // <-- IMPORT API SERVICE, pastikan path ini benar
import 'package:intl/intl.dart';
import 'dart:async';

class PenukaranPoinScreen extends StatefulWidget {
  const PenukaranPoinScreen({super.key});

  @override
  _PenukaranPoinScreenState createState() => _PenukaranPoinScreenState();
}

class _PenukaranPoinScreenState extends State<PenukaranPoinScreen> {
  int poin = 0;
  double saldo = 0;
  bool _isLoading = true;
  bool _isSubmitting = false; // Untuk loading saat proses tukar

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initNotification();
    _loadUserDataFromServer(); // Menggunakan fungsi yang mengambil data dari server
  }

  Future<void> _initNotification() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Sesuaikan dengan nama ikon Anda
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showSuccessNotification(
    int jumlahPoinDitukar,
    int saldoDidapatDariPenukaran,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'poin_channel_id', // ID channel yang unik
          'Penukaran Poin',
          channelDescription:
              'Notifikasi terkait aktivitas penukaran poin pengguna',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher', // Sesuaikan
          color: Colors.green,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      ), // ID notifikasi unik
      'Penukaran Poin Berhasil!',
      '$jumlahPoinDitukar poin berhasil ditukar menjadi ${currencyFormatter.format(saldoDidapatDariPenukaran)}.',
      notificationDetails,
    );

    // Catat ke riwayat lokal
    final notificationData = {
      'kegiatan': 'Penukaran Poin',
      'jenis': 'Penukaran Berhasil', // Lebih spesifik
      'tanggal': DateTime.now().toIso8601String(),
      'poin': jumlahPoinDitukar.toString(), // Poin yang berkurang
      'saldo':
          saldoDidapatDariPenukaran
              .toString(), // Saldo yang bertambah dari penukaran ini
    };
    await SharedPrefs.tambahRiwayat(notificationData);
  }

  Future<void> _loadUserDataFromServer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    String? userId = SharedPrefs.getUserId();
    if (userId == null || userId.isEmpty) {
      // Periksa juga jika userId kosong
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _customDialog(
          title: "Error Akses Data",
          content:
              "User ID tidak ditemukan. Silakan login ulang untuk melanjutkan.",
          confirmText: "Login",
          icon: Icons.no_accounts_rounded,
          iconColor: Colors.orange.shade600,
          onConfirm: () {
            // Navigasi ke halaman login jika perlu
            // Navigator.of(context).pushReplacementNamed('/login');
          },
        );
      }
      return;
    }

    try {
      // Ambil poin dan saldo secara paralel dari server
      final results = await Future.wait([
        ApiService.getUserPoints(userId),
        ApiService.getUserBalance(userId),
      ]);

      if (mounted) {
        setState(() {
          poin = results[0] as int;
          saldo = results[1] as double;
          _isLoading = false;
        });
        // Simpan juga ke SharedPrefs agar data lokal terupdate
        // Anda mungkin perlu mengambil username lagi jika ingin menyimpan data user lengkap
        String? username = await SharedPrefs.getUsername();
        await SharedPrefs.saveUserData(userId, username ?? 'User', saldo, poin);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Jika gagal load dari server, coba load dari local sebagai fallback
          poin = SharedPrefs.getPoin();
          saldo = SharedPrefs.getSaldo();
        });
        _customDialog(
          title: "Gagal Memuat Data",
          content:
              "Tidak dapat mengambil data terbaru dari server: ${e.toString()}.\n\nSaat ini menampilkan data yang tersimpan secara lokal.",
          confirmText: "Mengerti",
          icon: Icons.signal_wifi_off_rounded,
          iconColor: Colors.orange.shade600,
        );
      }
    }
  }

  void _handleTukarPoin(
    int jumlahPoinTukar,
    int nilaiSaldoDapatDariOpsi,
  ) async {
    if (_isSubmitting) return; // Mencegah multiple submit

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    String? userId = SharedPrefs.getUserId();
    if (userId == null || userId.isEmpty) {
      _customDialog(
        title: "Aksi Dibatalkan",
        content: "User ID tidak valid atau tidak ditemukan. Mohon login ulang.",
        confirmText: "OK",
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade600,
      );
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    // Validasi poin sisi client (berdasarkan data state yang sudah di-load)
    // Server akan melakukan validasi akhir juga.
    int poinSaatIni = poin;

    if (poinSaatIni < jumlahPoinTukar) {
      _customDialog(
        title: "Poin Tidak Cukup",
        content:
            "Poin Anda saat ini ($poinSaatIni) tidak mencukupi untuk melakukan penukaran $jumlahPoinTukar poin.",
        confirmText: "OK",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange.shade700,
      );
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    bool? confirm = await _customDialog(
      title: "Konfirmasi Penukaran",
      content:
          "Anda yakin ingin menukar $jumlahPoinTukar poin menjadi ${currencyFormatter.format(nilaiSaldoDapatDariOpsi)}?",
      confirmText: "Ya, Tukar",
      cancelText: "Batal",
      icon: Icons.help_outline_rounded,
      iconColor: Colors.blue.shade600,
    );

    if (confirm == true) {
      try {
        // Panggil API untuk tukar poin
        final responseData = await ApiService.tukarPoinRemote(
          userId,
          jumlahPoinTukar,
          nilaiSaldoDapatDariOpsi, // Kirim nilai saldo yang sudah ditentukan dari UI
        );

        // Jika sukses, server akan mengembalikan data poin dan saldo terbaru
        final int poinBaruServer = responseData['poin_tersisa'] as int;
        final double saldoBaruServer =
            (responseData['saldo_sekarang'] as num).toDouble();
        // saldo_didapat dari server seharusnya sama dengan nilaiSaldoDapatDariOpsi
        // atau ambil dari server untuk konfirmasi
        final int saldoDidapatKonfirmasiServer =
            (responseData['saldo_didapat'] as num).toInt();

        if (mounted) {
          setState(() {
            poin = poinBaruServer;
            saldo = saldoBaruServer;
          });
        }

        // Simpan data terbaru ke SharedPrefs
        String? username = (await SharedPrefs.getUsername()) ?? 'User';
        await SharedPrefs.saveUserData(
          userId,
          username,
          saldoBaruServer,
          poinBaruServer,
        );

        _showSuccessNotification(jumlahPoinTukar, saldoDidapatKonfirmasiServer);
        _customDialog(
          title: "Penukaran Berhasil",
          content:
              "$jumlahPoinTukar poin telah berhasil ditukar menjadi ${currencyFormatter.format(saldoDidapatKonfirmasiServer)}.",
          confirmText: "Luar Biasa!",
          icon: Icons.check_circle_outline_rounded,
          iconColor: Colors.green.shade600,
        );
      } catch (e) {
        String errorMessage = e.toString();
        if (e is TimeoutException) {
          errorMessage =
              "Waktu tunggu koneksi ke server habis. Periksa koneksi internet Anda.";
        } else if (e is Exception && e.toString().contains('Exception: ')) {
          // Mengambil pesan error yang lebih bersih dari Exception
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
        _customDialog(
          title: "Penukaran Gagal",
          content: "Terjadi kesalahan saat proses penukaran: $errorMessage",
          confirmText: "Coba Lagi Nanti",
          icon: Icons.error_rounded,
          iconColor: Colors.red.shade600,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      // Jika pengguna membatalkan konfirmasi
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool?> _customDialog({
    required String title,
    required String content,
    required String confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onConfirm, // Opsional callback untuk tombol konfirmasi
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible:
          cancelText == null, // Tidak bisa dismiss jika hanya ada 1 tombol
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: icon != null ? Icon(icon, color: iconColor, size: 48) : null,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color:
                    iconColor ?? Theme.of(context).textTheme.titleLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              content,
              style: GoogleFonts.poppins(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: <Widget>[
              if (cancelText != null)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelText,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (cancelText != null) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor ?? Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                    if (onConfirm != null) {
                      onConfirm();
                    }
                  },
                  child: Text(
                    confirmText,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTukarOpsiItem({
    required int poinTukar,
    required int saldoTukar,
    required Color itemAccentColor,
    required Color itemBackgroundColor,
  }) {
    bool canTukar = poin >= poinTukar;
    return Card(
      elevation: canTukar ? 3.0 : 1.0,
      margin: const EdgeInsets.symmetric(vertical: 7.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              canTukar
                  ? itemAccentColor.withOpacity(0.7)
                  : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      color: canTukar ? itemBackgroundColor : Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            canTukar && !_isSubmitting
                ? () => _handleTukarPoin(poinTukar, saldoTukar)
                : null,
        splashColor: itemAccentColor.withOpacity(0.2),
        highlightColor: itemAccentColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tukar $poinTukar Poin",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            canTukar
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.black.withOpacity(0.8))
                                : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Dapatkan ${currencyFormatter.format(saldoTukar)}",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            canTukar ? itemAccentColor : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (_isSubmitting && canTukar)
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 2),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(itemAccentColor),
                  ),
                )
              else if (canTukar)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: itemAccentColor,
                  size: 18,
                )
              else if (!canTukar)
                Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Penukaran Poin",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.green.shade600),
              )
              : RefreshIndicator(
                onRefresh:
                    _loadUserDataFromServer, // Menggunakan fungsi yang memuat dari server
                color: Colors.green.shade600,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 30),
                      Text(
                        "Pilihan Penukaran",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTukarOpsiItem(
                        poinTukar: 10,
                        saldoTukar: 1000,
                        itemAccentColor: Colors.orange.shade700,
                        itemBackgroundColor: Colors.orange.shade50,
                      ),
                      _buildTukarOpsiItem(
                        poinTukar: 50,
                        saldoTukar: 5500,
                        itemAccentColor: Colors.red.shade600,
                        itemBackgroundColor: Colors.red.shade50,
                      ),
                      _buildTukarOpsiItem(
                        poinTukar: 100,
                        saldoTukar: 12000,
                        itemAccentColor: Colors.purple.shade600,
                        itemBackgroundColor: Colors.purple.shade50,
                      ),
                      _buildTukarOpsiItem(
                        poinTukar: 200,
                        saldoTukar: 25000,
                        itemAccentColor: Colors.blue.shade700,
                        itemBackgroundColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.green.withOpacity(0.3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: Colors.yellow.shade600,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  "Poin Anda Saat Ini",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.decimalPattern('id_ID').format(poin),
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.5), thickness: 1),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.lightBlue.shade100,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  "Total Saldo Anda",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(saldo),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
