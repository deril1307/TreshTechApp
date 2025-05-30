// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, await_only_futures, unused_import, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'dart:async';
import '../main.dart';

class TarikSaldoScreen extends StatefulWidget {
  const TarikSaldoScreen({super.key}); // Tambahkan const dan Key

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
  bool _isLoading = false; // Untuk loading indicator pada tombol

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- LOGIKA BACKEND (TIDAK DIUBAH KECUALI UNTUK MOUNTED CHECKS) ---
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showUINotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'tarik_saldo_channel_ui', // Channel ID unik
          'Tarik Saldo UI Notifications',
          channelDescription: 'Notifikasi UI untuk transaksi tarik saldo',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      1,
      title,
      body,
      platformDetails,
    ); // ID notifikasi berbeda
  }

  Future<void> _loadUserData() async {
    double savedSaldo = await SharedPrefs.getSaldo();
    if (mounted) {
      setState(() {
        saldo = savedSaldo;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
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
    // ignore: unused_local_variable
    final theme = Theme.of(context); // Ambil theme untuk snackbar
    if (_selectedAmount == null) {
      _showCustomSnackbar(
        'Harap pilih jumlah saldo terlebih dahulu.',
        isError: true,
        context: context,
      );
      return;
    }

    final jumlahTarik = double.tryParse(
      _selectedAmount!.replaceAll('.', '').replaceAll('Rp ', ''),
    );

    if (jumlahTarik == null) {
      _showCustomSnackbar(
        'Jumlah saldo tidak valid.',
        isError: true,
        context: context,
      );
      return;
    }

    final String? userIdString =
        await SharedPrefs.getUserId(); // Jadikan async jika SharedPrefs.getUserId async

    if (userIdString == null) {
      _showCustomSnackbar(
        'User ID tidak ditemukan. Mohon login ulang.',
        isError: true,
        context: context,
      );
      return;
    }

    if (saldo < jumlahTarik) {
      _showCustomSnackbar(
        'Saldo Anda tidak mencukupi.',
        isError: true,
        context: context,
      );
      return;
    }

    bool? confirm = await _showConfirmationDialog(
      title: "Konfirmasi Penarikan",
      content: "Anda yakin ingin menarik saldo sebesar Rp$_selectedAmount?",
      confirmText: "Ya, Tarik",
      cancelText: "Batal",
    );

    if (confirm != true) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final result = await ApiService.tarikSaldo(
        userId: userIdString,
        amount: jumlahTarik,
      );

      if (mounted) {
        if (result['status'] == 'success') {
          var newBalance = result['new_balance'];
          double updatedSaldo = saldo; // Default ke saldo saat ini
          if (newBalance is int) {
            updatedSaldo = newBalance.toDouble();
          } else if (newBalance is double) {
            updatedSaldo = newBalance;
          } else if (newBalance is String) {
            updatedSaldo = double.tryParse(newBalance) ?? saldo;
          }

          setState(() {
            saldo = updatedSaldo;
            _selectedAmount = null;
          });

          await SharedPrefs.saveSaldo(saldo);
          final formattedAmount = jumlahTarik
              .toStringAsFixed(0)
              .replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]}.',
              );
          final successMessage =
              'Permintaan tarik saldo Rp $formattedAmount telah dikirim.';

          await _showUINotification('Tarik Saldo Berhasil', successMessage);
          await SharedPrefs.tambahRiwayat({
            'kegiatan':
                'Penarikan Saldo Sebesar Rp $formattedAmount', // Deskripsi lebih jelas
            'jenis': 'Tarik Saldo',
            'tanggal': DateTime.now().toIso8601String(),
            'saldo': "Rp $formattedAmount",
          });
          _showCustomSnackbar(successMessage, context: context); // Pass context
        } else {
          _showCustomSnackbar(
            result['message'] ?? 'Gagal melakukan penarikan saldo.',
            isError: true,
            context: context,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackbar(
          'Terjadi kesalahan: ${e.toString()}',
          isError: true,
          context: context,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --- AKHIR LOGIKA BACKEND ---

  void _showCustomSnackbar(
    String message, {
    bool isError = false,
    required BuildContext context,
  }) {
    if (!mounted) return;
    final theme = Theme.of(context); // Ambil theme dari context yang di-pass
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color:
                isError
                    ? theme.colorScheme.onError
                    : Colors.white, // Warna teks disesuaikan
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor:
            isError
                ? theme.colorScheme.error
                : theme.primaryColor, // Warna dari tema
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
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            // Gunakan dialogContext
            backgroundColor: theme.cardColor, // Warna background dialog
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: customColors.titleTextColor, // Warna judul dari tema
              ),
            ),
            content: Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                color: customColors.bodyTextColor,
              ),
            ), // Warna konten dari tema
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              if (cancelText != null)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    cancelText,
                    style: GoogleFonts.poppins(
                      color:
                          customColors
                              .secondaryTextColor, // Warna tombol batal dari tema
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      theme.primaryColor, // Warna tombol konfirmasi dari tema
                  foregroundColor:
                      theme.colorScheme.onPrimary, // Warna teks tombol
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  confirmText,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final formattedSaldo = saldo
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Tarik Saldo",
          // Style dari AppBarTheme di main.dart
        ),
        // backgroundColor dan iconTheme dari AppBarTheme
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(
                  isDarkMode ? 0.15 : 0.08,
                ), // Warna kartu saldo
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.primaryColor,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Saldo Anda Saat Ini",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: customColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rp $formattedSaldo",
                          style: GoogleFonts.poppins(
                            fontSize: 28, // Ukuran font saldo lebih besar
                            fontWeight: FontWeight.bold,
                            color:
                                theme
                                    .primaryColorDark, // Warna saldo lebih tegas
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Pilih Jumlah Penarikan",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: customColors.titleTextColor, // Warna judul dari tema
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: theme.cardColor, // Warna background dropdown
                border: Border.all(color: theme.dividerColor, width: 1.2),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
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
                    color: theme.primaryColor,
                    size: 30,
                  ),
                  hint: Text(
                    "Pilih nominal",
                    style: GoogleFonts.poppins(
                      color: theme.hintColor,
                      fontSize: 16,
                    ),
                  ),
                  items:
                      _amountOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            'Rp $value',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: customColors.bodyTextColor,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedAmount = newValue);
                  },
                  dropdownColor:
                      theme.cardColor, // Warna background menu dropdown
                  style: GoogleFonts.poppins(
                    color: customColors.bodyTextColor,
                    fontSize: 16,
                  ), // Style teks item terpilih
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
                    fontSize: 14.5,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                icon:
                    _isLoading
                        ? const SizedBox.shrink()
                        : Icon(
                          Icons.send_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 22,
                        ),
                label:
                    _isLoading
                        ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                        : Text(
                          "Tarik Saldo Sekarang",
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                onPressed: _isLoading ? null : _tarikSaldo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
