import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';

class PenukaranPoinScreen extends StatefulWidget {
  @override
  _PenukaranPoinScreenState createState() => _PenukaranPoinScreenState();
}

class _PenukaranPoinScreenState extends State<PenukaranPoinScreen> {
  int poin = 0;
  double saldo = 0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0,
      'Penukaran Berhasil!',
      '$jumlahPoin poin ditukar menjadi Rp$saldoTukar.',
      notificationDetails,
    );

    // Save notification to SharedPreferences
    final notificationData = {
      'kegiatan': 'Penukaran Poin',
      'jenis': 'Penukaran',
      'tanggal': DateTime.now().toString(),
      'poin': jumlahPoin.toString(),
      'saldo': saldoTukar.toString(),
    };
    await SharedPrefs.tambahRiwayat(notificationData);
  }

  Future<void> _loadUserData() async {
    int savedPoin = SharedPrefs.getPoin();
    double savedSaldo = SharedPrefs.getSaldo();
    setState(() {
      poin = savedPoin;
      saldo = savedSaldo;
    });
  }

  void _tukarPoin(int jumlahPoin, int nilaiTukar) async {
    if (poin < jumlahPoin) {
      _customDialog(
        title: "Gagal",
        content: "Minimal $jumlahPoin poin untuk penukaran ini.",
        confirmText: "OK",
      );
      return;
    }

    bool? confirm = await _customDialog(
      title: "Konfirmasi",
      content: "Tukar $jumlahPoin poin menjadi Rp$nilaiTukar?",
      confirmText: "Tukar",
      cancelText: "Batal",
    );

    if (confirm == true) {
      setState(() {
        poin -= jumlahPoin;
        saldo += nilaiTukar;
      });

      await SharedPrefs.saveUserData(
        SharedPrefs.getUserId()!,
        (await SharedPrefs.getUsername()) ?? '',
        saldo,
        poin,
      );

      _customDialog(
        title: "Berhasil",
        content: "$jumlahPoin poin berhasil ditukar menjadi Rp$nilaiTukar.",
        confirmText: "OK",
      );

      // Show success notification and save it to SharedPreferences
      _showSuccessNotification(jumlahPoin, nilaiTukar);
    }
  }

  Future<bool?> _customDialog({
    required String title,
    required String content,
    required String confirmText,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(content, style: GoogleFonts.poppins()),
            actions: [
              if (cancelText != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelText, style: GoogleFonts.poppins()),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmText,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTukarButton(int poinTukar, int saldoTukar) {
    return ElevatedButton(
      onPressed: () => _tukarPoin(poinTukar, saldoTukar),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 18, 148, 25),
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        "Tukar $poinTukar Poin ke Rp$saldoTukar",
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Penukaran Poin", style: GoogleFonts.poppins()),
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.green.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 50,
                          color: Colors.green.shade600,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Poin Anda",
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                        Text(
                          "$poin",
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        SizedBox(height: 20),
                        Divider(thickness: 1.5),
                        SizedBox(height: 20),
                        Text(
                          "Saldo Anda",
                          style: GoogleFonts.poppins(fontSize: 18),
                        ),
                        Text(
                          "Rp ${saldo.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  "Tukar Poin",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                SizedBox(height: 20),
                _buildTukarButton(10, 1000),
                SizedBox(height: 15),
                _buildTukarButton(50, 2000),
                SizedBox(height: 15),
                _buildTukarButton(100, 5000),
                SizedBox(height: 15),
                _buildTukarButton(200, 15000),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
