import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

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
    final Map<String, String> decodedPayload = Map<String, String>.from(
      jsonDecode(payload),
    );

    final newItem = {
      'kegiatan': decodedPayload['kegiatan'] ?? '',
      'jenis': decodedPayload['jenis'] ?? '',
      'tanggal': DateTime.now().toString().substring(0, 16),
      'poin': decodedPayload['poin'] ?? '',
      'saldo': decodedPayload['saldo'] ?? '',
    };

    await SharedPrefs.tambahRiwayat(newItem); // Menambah riwayat ke SharedPrefs
    loadRiwayat(); // Memuat kembali riwayat

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Riwayat baru ditambahkan: ${decodedPayload['kegiatan']}",
        ),
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

  // Fungsi untuk menghapus riwayat pada index tertentu
  void _deleteHistory(int index) async {
    await SharedPrefs.hapusRiwayatByIndex(
      index,
    ); // Menghapus riwayat di SharedPrefs
    loadRiwayat(); // Memuat kembali riwayat setelah penghapusan

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Riwayat berhasil dihapus."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Fungsi untuk menghapus semua riwayat
  void _clearAllHistory() async {
    await SharedPrefs.hapusSemuaRiwayat(); // Menghapus semua riwayat di SharedPrefs
    loadRiwayat(); // Memuat kembali riwayat setelah penghapusan

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Semua riwayat berhasil dihapus."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Aktivitas", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            tooltip: 'Hapus Semua Riwayat',
            onPressed:
                _clearAllHistory, // Menambahkan fungsi untuk menghapus semua riwayat
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
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Riwayat Terbaru",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) {
                          final item = riwayat[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(
                                  getIconByJenis(item['jenis'] ?? ''),
                                  color: Colors.green.shade800,
                                ),
                              ),
                              title: Text(
                                item['kegiatan'] ?? '-',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              subtitle: Text(
                                item['tanggal'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              children: <Widget>[
                                ListTile(
                                  title: Text(
                                    'Detail: ${item['kegiatan']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Tanggal: ${item['tanggal']}\nPoin: ${item['poin']}\nSaldo: ${item['saldo']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _deleteHistory(index),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Fungsi untuk menampilkan notifikasi
  Future<void> _showSuccessNotification(int jumlahPoin, int saldoTukar) async {
    // Membuat data riwayat sebagai map
    Map<String, String> dataRiwayat = {
      "kegiatan": "Penukaran Poin",
      "jenis": "Penukaran",
      "tanggal": DateTime.now().toString(),
      "poin": jumlahPoin.toString(),
      "saldo": saldoTukar.toString(),
    };

    // Mengubah ke JSON string untuk payload
    String payload = jsonEncode(dataRiwayat);

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

    // Menampilkan notifikasi
    await flutterLocalNotificationsPlugin.show(
      0,
      'Aktivitas Baru: Penukaran Poin',
      'Anda berhasil menukar $jumlahPoin poin menjadi Rp$saldoTukar.',
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> onSelectNotification(String? payload) async {
    if (payload != null) {
      final Map<String, dynamic> data = jsonDecode(payload);
      print("Notifikasi dibuka dengan data:");
      print(data);
    }
  }
}
