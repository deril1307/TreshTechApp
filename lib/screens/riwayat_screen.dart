import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RiwayatScreen extends StatefulWidget {
  @override
  _RiwayatScreenState createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<Map<String, String>> riwayat = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    loadRiwayat();
    _initializeNotifications();
  }

  // Inisialisasi notifikasi lokal
  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationSelected(payload);
        }
      },
    );
  }

  // Fungsi saat notifikasi dipilih
  void _handleNotificationSelected(String payload) async {
    final newItem = {
      'kegiatan': payload,
      'jenis': 'Penukaran Poin',
      'tanggal': DateTime.now().toString().substring(0, 16),
    };
    await SharedPrefs.tambahRiwayat(newItem); // Menambah riwayat ke SharedPrefs
    loadRiwayat(); // Memuat kembali riwayat

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Riwayat baru ditambahkan: $payload"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Menampilkan riwayat dari SharedPreferences
  void loadRiwayat() {
    final data = SharedPrefs.getRiwayat();
    setState(() {
      riwayat = data;
    });
  }

  // Menentukan ikon sesuai jenis aktivitas
  IconData getIconByJenis(String jenis) {
    switch (jenis) {
      case 'Sampah Metal':
        return Icons.auto_awesome;
      case 'Sampah Non-Metal':
        return Icons.recycling;
      case 'Penukaran':
      case 'Tarik Saldo':
        return Icons.attach_money;
      case 'Top Up':
        return Icons.add_card;
      case 'Withdraw':
        return Icons.remove_circle;
      case 'Notifikasi Aktivitas':
        return Icons.notifications_active;
      default:
        return Icons.history;
    }
  }

  // Menampilkan data riwayat
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Aktivitas", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.notification_add),
            tooltip: 'Trigger Notifikasi Simulasi',
            onPressed:
                () => _showSuccessNotification(
                  50,
                  2000,
                ), // Simulasi Penukaran Poin
          ),
        ],
      ),
      body:
          riwayat.isEmpty
              ? Center(
                child: Text(
                  "Belum ada riwayat.",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              )
              : ListView.builder(
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
                        item['kegiatan'] ?? '-',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      subtitle: Text(
                        item['tanggal'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      leading: Icon(
                        getIconByJenis(item['jenis'] ?? ''),
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
    );
  }

  // Fungsi untuk menampilkan notifikasi
  Future<void> _showSuccessNotification(int jumlahPoin, int saldoTukar) async {
    // Menambahkan detail pada payload notifikasi
    String payload =
        'Penukaran Poin: $jumlahPoin poin ditukar menjadi Rp$saldoTukar';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          channelDescription: 'Deskripsi channel notifikasi',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Menampilkan notifikasi dengan detail aktivitas
    await flutterLocalNotificationsPlugin.show(
      0,
      'Aktivitas Baru: Penukaran Poin',
      'Anda berhasil menukar $jumlahPoin poin menjadi Rp$saldoTukar.',
      notificationDetails,
      payload: payload,
    );
  }
}
