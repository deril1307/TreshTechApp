// ignore_for_file: await_only_futures, unused_import, library_private_types_in_public_api, deprecated_member_use, unnecessary_type_check, unnecessary_cast, unused_local_variable, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Import MyApp dan CustomThemeColors dari main.dart
// Sesuaikan path '../main.dart' jika struktur folder Anda berbeda
import '../main.dart'; // Asumsi main.dart ada di direktori parent

class PenukaranPoinScreen extends StatefulWidget {
  const PenukaranPoinScreen({super.key});

  @override
  _PenukaranPoinScreenState createState() => _PenukaranPoinScreenState();
}

class _PenukaranPoinScreenState extends State<PenukaranPoinScreen> {
  int poin = 0;
  double saldo = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int?
  _selectedPoinTukarForLoading; // Untuk melacak item mana yang sedang diproses

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
    _loadUserDataFromServer();
  }

  @override
  void dispose() {
    // Tidak ada controller yang perlu di-dispose di sini
    super.dispose();
  }

  Future<void> _initNotification() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Pastikan ikon ada
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      // Error initializing notifications
    }
  }

  Future<void> _showSuccessNotification(
    int jumlahPoinDitukar,
    int saldoDidapatDariPenukaran,
  ) async {
    // final theme = Theme.of(context); // Tidak digunakan untuk warna notifikasi di sini

    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'poin_channel_id_success_v3', // ID channel unik (ganti jika ada perubahan signifikan)
      'Penukaran Poin Sukses',
      channelDescription: 'Notifikasi untuk penukaran poin yang berhasil',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // color: theme.primaryColor, // Bisa ditambahkan jika ingin warna aksen notifikasi
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    try {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Penukaran Poin Berhasil!',
        '$jumlahPoinDitukar poin berhasil ditukar menjadi ${currencyFormatter.format(saldoDidapatDariPenukaran)}.',
        notificationDetails,
      );
    } catch (e) {
      // Error showing success notification
    }

    final notificationData = {
      'kegiatan': 'Penukaran $jumlahPoinDitukar Poin ke Saldo',
      'jenis': 'Penukaran Poin',
      'tanggal': DateTime.now().toIso8601String(),
      'poin': '-$jumlahPoinDitukar',
      'saldo': '+${currencyFormatter.format(saldoDidapatDariPenukaran)}',
    };
    try {
      await SharedPrefs.tambahRiwayat(notificationData);
    } catch (e) {
      // Error saving history to SharedPrefs
    }
  }

  Future<void> _loadUserDataFromServer() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String? userId = await SharedPrefs.getUserId();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        _customDialog(
          context: context,
          title: "Error Akses Data",
          content:
              "User ID tidak ditemukan. Silakan login ulang untuk melanjutkan.",
          confirmText: "Login",
          icon: Icons.no_accounts_rounded,
          iconColor: Theme.of(context).colorScheme.error,
          onConfirm: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      }
      return;
    }

    try {
      final results = await Future.wait([
        ApiService.getUserPoints(userId),
        ApiService.getUserBalance(userId),
      ]);

      if (mounted) {
        final fetchedPoin =
            results[0] is int
                ? results[0] as int
                : int.tryParse(results[0].toString()) ??
                    poin; // Fallback ke nilai state jika parse gagal
        final fetchedSaldo =
            results[1] is num
                ? (results[1] as num).toDouble()
                : double.tryParse(results[1].toString()) ?? saldo; // Fallback

        setState(() {
          poin = fetchedPoin;
          saldo = fetchedSaldo;
          _isLoading = false;
        });
        String? username = await SharedPrefs.getUsername();
        await SharedPrefs.saveUserData(userId, username ?? 'User', saldo, poin);
      }
    } catch (e) {
      // Error loading user data from server
      if (mounted) {
        // Coba ambil dari SharedPreferences sebagai fallback jika server gagal
        int localPoin = await SharedPrefs.getPoin();
        double localSaldo = await SharedPrefs.getSaldo();
        setState(() {
          _isLoading = false;
          poin = localPoin; // Gunakan data lokal
          saldo = localSaldo; // Gunakan data lokal
        });
        _customDialog(
          context: context,
          title: "Gagal Memuat Data",
          content:
              "Tidak dapat mengambil data terbaru dari server. Menampilkan data yang tersimpan.",
          confirmText: "Mengerti",
          icon: Icons.signal_wifi_off_rounded,
          iconColor: Colors.orange.shade700,
        );
      }
    }
  }

  void _handleTukarPoin(
    int jumlahPoinTukar,
    int nilaiSaldoDapatDariOpsi,
  ) async {
    if (_isSubmitting)
      return; // Mencegah multiple submit jika sudah ada yang diproses
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      _selectedPoinTukarForLoading =
          jumlahPoinTukar; // Tandai item mana yang sedang diproses
    });

    String? userId = await SharedPrefs.getUserId();
    if (userId == null || userId.isEmpty) {
      _customDialog(
        context: context,
        title: "Aksi Dibatalkan",
        content: "User ID tidak valid atau tidak ditemukan. Mohon login ulang.",
        confirmText: "OK",
        icon: Icons.error_outline_rounded,
        iconColor: Theme.of(context).colorScheme.error,
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedPoinTukarForLoading = null;
        });
      }
      return;
    }

    int poinSaatIni = poin;
    if (poinSaatIni < jumlahPoinTukar) {
      _customDialog(
        context: context,
        title: "Poin Tidak Cukup",
        content:
            "Poin Anda saat ini ($poinSaatIni) tidak mencukupi untuk penukaran $jumlahPoinTukar poin.",
        confirmText: "OK",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange.shade700,
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedPoinTukarForLoading = null;
        });
      }
      return;
    }

    bool? confirm = await _customDialog(
      context: context,
      title: "Konfirmasi Penukaran",
      content:
          "Anda yakin ingin menukar $jumlahPoinTukar poin menjadi ${currencyFormatter.format(nilaiSaldoDapatDariOpsi)}?",
      confirmText: "Ya, Tukar",
      cancelText: "Batal",
      icon: Icons.help_outline_rounded,
      iconColor: Theme.of(context).primaryColor,
    );

    if (confirm == true) {
      try {
        final responseData = await ApiService.tukarPoinRemote(
          userId,
          jumlahPoinTukar,
          nilaiSaldoDapatDariOpsi,
        );

        final dynamic poinSisaRaw = responseData['poin_tersisa'];
        final dynamic saldoSekarangRaw = responseData['saldo_sekarang'];
        final dynamic saldoDidapatRaw = responseData['saldo_didapat'];

        if (poinSisaRaw == null ||
            saldoSekarangRaw == null ||
            saldoDidapatRaw == null) {
          throw Exception(
            "Format respons API tidak sesuai atau data tidak lengkap.",
          );
        }

        final int poinBaruServer =
            poinSisaRaw is int
                ? poinSisaRaw
                : int.tryParse(poinSisaRaw.toString()) ??
                    poin; // Fallback ke poin lama jika parse gagal
        final double saldoBaruServer =
            saldoSekarangRaw is num
                ? (saldoSekarangRaw).toDouble()
                : double.tryParse(saldoSekarangRaw.toString()) ??
                    saldo; // Fallback
        final int saldoDidapatKonfirmasiServer =
            saldoDidapatRaw is num
                ? (saldoDidapatRaw).toInt()
                : int.tryParse(saldoDidapatRaw.toString()) ?? 0;

        if (mounted) {
          setState(() {
            poin = poinBaruServer;
            saldo = saldoBaruServer;
          });
        }

        String? username = (await SharedPrefs.getUsername()) ?? 'User';
        await SharedPrefs.saveUserData(
          userId,
          username,
          saldoBaruServer,
          poinBaruServer,
        );

        _showSuccessNotification(jumlahPoinTukar, saldoDidapatKonfirmasiServer);
        _customDialog(
          context: context,
          title: "Penukaran Berhasil",
          content:
              "$jumlahPoinTukar poin telah berhasil ditukar menjadi ${currencyFormatter.format(saldoDidapatKonfirmasiServer)}.",
          confirmText: "Luar Biasa!",
          icon: Icons.check_circle_outline_rounded,
          iconColor: Theme.of(context).primaryColor,
        );
      } catch (e) {
        String errorMessage =
            "Gagal melakukan penukaran. Silakan coba lagi nanti.";
        if (e is TimeoutException) {
          errorMessage =
              "Waktu tunggu koneksi ke server habis. Periksa koneksi Anda.";
        } else if (e is Exception) {
          final msg = e.toString();
          if (msg.contains("SocketException") ||
              msg.contains("HandshakeException") ||
              msg.contains("HttpException")) {
            errorMessage =
                "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.";
          } else if (msg.contains("FormatException")) {
            errorMessage = "Terjadi kesalahan format data dari server.";
          } else if (msg.startsWith("Exception: ")) {
            errorMessage = msg.replaceFirst('Exception: ', '');
          } else {
            errorMessage = "Terjadi kesalahan tidak terduga: $msg";
          }
        }
        _customDialog(
          context: context,
          title: "Penukaran Gagal",
          content: errorMessage,
          confirmText: "OK",
          icon: Icons.error_rounded,
          iconColor: Theme.of(context).colorScheme.error,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _selectedPoinTukarForLoading = null;
          });
        }
      }
    } else {
      // Pengguna membatalkan konfirmasi
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedPoinTukarForLoading = null;
        });
      }
    }
  }

  Future<bool?> _customDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onConfirm,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    return showDialog<bool>(
      context: context,
      barrierDismissible:
          cancelText == null && onConfirm == null, // Lebih fleksibel
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon:
                icon != null
                    ? Icon(
                      icon,
                      color: iconColor ?? theme.primaryColor,
                      size: 48,
                    )
                    : null,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: customColors.titleTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                color: customColors.bodyTextColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ), // Padding disesuaikan
            actions: <Widget>[
              if (cancelText != null)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: theme.dividerColor.withOpacity(0.8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      cancelText,
                      style: GoogleFonts.poppins(
                        color: customColors.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              if (cancelText != null) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor ?? theme.primaryColor,
                    foregroundColor:
                        Colors.white, // Teks putih untuk kontras yang baik
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    ); // Selalu pop dengan true jika tombol konfirmasi ditekan
                    if (onConfirm != null) {
                      onConfirm();
                    }
                  },
                  child: Text(
                    confirmText,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTukarOpsiItem({
    required BuildContext context,
    required int poinTukar,
    required int saldoTukar,
    required Color itemAccentColor,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    bool canTukar = poin >= poinTukar;

    Color cardBgColor;
    Color titleColor;
    Color subtitleColor;
    Color borderColor;
    double elevation;

    if (canTukar) {
      cardBgColor =
          isDarkMode
              ? itemAccentColor.withOpacity(0.25)
              : itemAccentColor.withOpacity(0.1);
      titleColor =
          customColors.titleTextColor ??
          (isDarkMode
              ? Colors.white.withOpacity(0.95)
              : Colors.black.withOpacity(0.87));
      subtitleColor = itemAccentColor;
      borderColor = itemAccentColor.withOpacity(0.7);
      elevation = 3.5;
    } else {
      cardBgColor = theme.cardColor.withOpacity(isDarkMode ? 0.2 : 0.7);
      titleColor = theme.hintColor.withOpacity(0.9);
      subtitleColor = theme.hintColor.withOpacity(0.8);
      borderColor = theme.dividerColor.withOpacity(0.6);
      elevation = 1.0;
    }

    bool isCurrentlySubmittingThisItem =
        _isSubmitting && _selectedPoinTukarForLoading == poinTukar;

    return Card(
      elevation: elevation,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: canTukar ? 1.5 : 1.0),
      ),
      color: cardBgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            canTukar &&
                    !_isSubmitting // Hanya bisa tap jika bisa tukar DAN tidak sedang ada proses submit lain
                ? () {
                  _handleTukarPoin(poinTukar, saldoTukar);
                }
                : null,
        splashColor: itemAccentColor.withOpacity(0.25),
        highlightColor: itemAccentColor.withOpacity(0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tukar $poinTukar Poin",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Dapatkan ${currencyFormatter.format(saldoTukar)}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isCurrentlySubmittingThisItem)
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 4),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(itemAccentColor),
                  ),
                )
              else if (canTukar)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: itemAccentColor,
                  size: 20,
                )
              else
                Icon(
                  Icons.lock_outline_rounded,
                  color: theme.hintColor.withOpacity(0.7),
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
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    // ignore: unused_local_variable
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text("Penukaran Poin")),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : RefreshIndicator(
                onRefresh: _loadUserDataFromServer,
                color: theme.primaryColor,
                backgroundColor: theme.cardColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(context),
                      const SizedBox(height: 30),
                      Text(
                        "Pilihan Penukaran",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: customColors.titleTextColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 10,
                        saldoTukar: 1000,
                        itemAccentColor: Colors.orange.shade700,
                      ),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 50,
                        saldoTukar: 5500,
                        itemAccentColor: Colors.red.shade600,
                      ),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 100,
                        saldoTukar: 12000,
                        itemAccentColor: Colors.purple.shade600,
                      ),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 200,
                        saldoTukar: 25000,
                        itemAccentColor: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: theme.primaryColor.withOpacity(isDarkMode ? 0.4 : 0.25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors:
                isDarkMode
                    ? [
                      theme.primaryColorDark.withOpacity(0.9),
                      theme.primaryColor.withOpacity(0.95),
                    ]
                    : [
                      theme.primaryColor,
                      theme.primaryColorLight.withOpacity(0.9),
                    ], // Sedikit penyesuaian opacity
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
                  size: 30,
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 10),
            Text(
              NumberFormat.decimalPattern('id_ID').format(poin),
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(1, 1.5),
                  ),
                ], // Shadow lebih halus
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.white.withOpacity(0.35), thickness: 0.8),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.lightBlue.shade100,
                  size: 30,
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 10),
            Text(
              currencyFormatter.format(saldo),
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 1,
                    color: Colors.black.withOpacity(0.25),
                    offset: Offset(1, 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
