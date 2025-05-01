import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:google_fonts/google_fonts.dart';

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

  double saldo = 0.0;
  int poin = 0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
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
    int savedPoin = await SharedPrefs.getPoin();
    setState(() {
      saldo = savedSaldo;
      poin = savedPoin;
    });
  }

  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isPermanentlyDenied) openAppSettings();
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
      _showSnackbar('Harap pilih jumlah saldo terlebih dahulu.');
      return;
    }

    final jumlahTarik = double.tryParse(
      _selectedAmount!.replaceAll('.', '').replaceAll('Rp ', ''),
    );

    if (jumlahTarik == null) {
      _showSnackbar('Jumlah saldo tidak valid.');
      return;
    }

    if (jumlahTarik <= saldo) {
      setState(() {
        saldo -= jumlahTarik;
        _selectedAmount = null;
      });

      await SharedPrefs.saveUserData(
        SharedPrefs.getUserId()!,
        (await SharedPrefs.getUsername()) ?? '',
        saldo,
        poin,
      );

      final formattedAmount = jumlahTarik
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );

      final successMessage =
          'Permintaan tarik saldo sebesar Rp $formattedAmount telah dikirim.';

      await _showNotification('Tarik Saldo Berhasil', successMessage);

      // Prepare notification data in the desired format
      final notificationData = {
        'kegiatan': 'Penarikan Saldo',
        'jenis': 'Tarik Saldo',
        'tanggal': DateTime.now().toString(),
        'saldo': formattedAmount,
      };

      // Save the notification data to SharedPreferences
      await SharedPrefs.tambahRiwayat(
        notificationData,
      ); // Save notification to history

      _showSnackbar(successMessage);
    } else {
      _showSnackbar('Saldo tidak cukup untuk tarik Rp $_selectedAmount.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedSaldo = saldo
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      appBar: AppBar(
        title: Text("Tarik Saldo", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Saldo saat ini",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              "Rp $formattedSaldo",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 30),

            Text(
              "Pilih jumlah saldo yang ingin ditarik",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 10),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAmount,
                  isExpanded: true,
                  hint: Text(
                    "Pilih jumlah saldo",
                    style: GoogleFonts.poppins(),
                  ),
                  items:
                      _amountOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            'Rp $value',
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedAmount = newValue);
                  },
                ),
              ),
            ),

            SizedBox(height: 40),

            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.send),
                label: Text(
                  "Tarik Saldo",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onPressed: _tarikSaldo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
