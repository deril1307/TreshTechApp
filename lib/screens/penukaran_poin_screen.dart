import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:intl/intl.dart'; // Untuk formatting angka

class PenukaranPoinScreen extends StatefulWidget {
  const PenukaranPoinScreen({super.key});

  @override
  _PenukaranPoinScreenState createState() => _PenukaranPoinScreenState();
}

class _PenukaranPoinScreenState extends State<PenukaranPoinScreen> {
  int poin = 0;
  double saldo = 0;
  bool _isLoading = true;

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
    _loadUserData();
    _initNotification();
  }

  Future<void> _initNotification() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showSuccessNotification(int jumlahPoin, int saldoTukar) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'poin_channel',
          'Penukaran Poin',
          channelDescription: 'Notifikasi penukaran poin',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.green,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Penukaran Berhasil!',
      '$jumlahPoin poin ditukar menjadi ${currencyFormatter.format(saldoTukar)}.',
      notificationDetails,
    );
    final notificationData = {
      'kegiatan': 'Penukaran Poin',
      'jenis': 'Penukaran',
      'tanggal': DateTime.now().toIso8601String(),
      'poin': jumlahPoin.toString(),
      'saldo': saldoTukar.toString(),
    };
    await SharedPrefs.tambahRiwayat(notificationData);
  }

  Future<void> _loadUserData() async {
    int savedPoin = SharedPrefs.getPoin();
    double savedSaldo = SharedPrefs.getSaldo();
    if (mounted) {
      setState(() {
        poin = savedPoin;
        saldo = savedSaldo;
        _isLoading = false;
      });
    }
  }

  void _tukarPoin(int jumlahPoin, int nilaiTukar) async {
    if (poin < jumlahPoin) {
      _customDialog(
        title: "Gagal",
        content: "Minimal $jumlahPoin poin untuk penukaran ini.",
        confirmText: "OK",
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade600,
      );
      return;
    }
    bool? confirm = await _customDialog(
      title: "Konfirmasi",
      content:
          "Tukar $jumlahPoin poin menjadi ${currencyFormatter.format(nilaiTukar)}?",
      confirmText: "Tukar",
      cancelText: "Batal",
      icon: Icons.help_outline_rounded,
      iconColor: Colors.blue.shade600,
    );
    if (confirm == true) {
      final userId = SharedPrefs.getUserId();
      final username = (await SharedPrefs.getUsername()) ?? '';
      if (userId == null) {
        _customDialog(
          title: "Error",
          content: "User ID tidak ditemukan. Silakan login ulang.",
          confirmText: "OK",
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red.shade600,
        );
        return;
      }
      if (mounted) {
        setState(() {
          poin -= jumlahPoin;
          saldo += nilaiTukar;
        });
      }
      await SharedPrefs.saveUserData(userId, username, saldo, poin);
      _showSuccessNotification(jumlahPoin, nilaiTukar);
      _customDialog(
        title: "Berhasil",
        content:
            "$jumlahPoin poin berhasil ditukar menjadi ${currencyFormatter.format(nilaiTukar)}.",
        confirmText: "Selesai",
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.green.shade600,
      );
    }
  }

  Future<bool?> _customDialog({
    required String title,
    required String content,
    required String confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<bool>(
      context: context,
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
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              content,
              style: GoogleFonts.poppins(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (cancelText != null)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: (iconColor ?? Colors.green).withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? Colors.green,
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
    // IconData sudah dihapus dari parameter
    required Color itemAccentColor,
    required Color itemBackgroundColor,
  }) {
    bool canTukar = poin >= poinTukar;
    return Card(
      elevation: canTukar ? 4.5 : 1.5, // Sedikit tingkatkan elevasi
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Konsisten
        side: BorderSide(
          color:
              canTukar
                  ? itemAccentColor.withOpacity(0.8) // Border lebih tegas
                  : Colors.grey.shade300,
          width: 1.5, // Border sedikit lebih tebal
        ),
      ),
      color: canTukar ? itemBackgroundColor : Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canTukar ? () => _tukarPoin(poinTukar, saldoTukar) : null,
        splashColor: itemAccentColor.withOpacity(0.2),
        highlightColor: itemAccentColor.withOpacity(0.1),
        child: Padding(
          // Padding disesuaikan karena tidak ada ikon
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Row(
            children: [
              // CircleAvatar dan SizedBox untuk ikon telah dihapus
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tukar $poinTukar Poin",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: canTukar ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5), // Sedikit tambah jarak
                    Text(
                      "Dapatkan ${currencyFormatter.format(saldoTukar)}",
                      style: GoogleFonts.poppins(
                        fontSize: 16, // Sedikit perbesar font
                        fontWeight: FontWeight.bold, // Dibuat bold
                        color:
                            canTukar ? itemAccentColor : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (canTukar)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: itemAccentColor, // Warna ikon panah disesuaikan
                  size: 20,
                ),
              if (!canTukar)
                Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
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
                onRefresh: _loadUserData,
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
                        // iconData: Icons.star_rounded, // Dihapus
                        itemAccentColor:
                            Colors.orange.shade700, // Warna lebih cerah/kontras
                        itemBackgroundColor:
                            Colors
                                .orange
                                .shade100, // Latar belakang lebih cerah
                      ),
                      _buildTukarOpsiItem(
                        poinTukar: 50,
                        saldoTukar: 5500,
                        // iconData: Icons.stars_rounded, // Dihapus
                        itemAccentColor: Colors.red.shade600,
                        itemBackgroundColor: Colors.red.shade100,
                      ),
                      _buildTukarOpsiItem(
                        poinTukar: 100,
                        saldoTukar: 12000,
                        // iconData: Icons.emoji_events_rounded, // Dihapus
                        itemAccentColor: Colors.purple.shade600,
                        itemBackgroundColor: Colors.purple.shade100,
                      ),
                      _buildTukarOpsiItem(
                        poinTukar: 200,
                        saldoTukar: 25000,
                        // iconData: Icons.military_tech_rounded, // Dihapus
                        itemAccentColor:
                            Colors
                                .blue
                                .shade700, // Ganti Teal ke Biru untuk variasi
                        itemBackgroundColor: Colors.blue.shade100,
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
