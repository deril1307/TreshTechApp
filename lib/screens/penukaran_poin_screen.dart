// ignore_for_file: await_only_futures, unused_import, library_private_types_in_public_api, deprecated_member_use, unnecessary_type_check, unnecessary_cast, unused_local_variable, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../main.dart';
import 'package:tubes_mobile/screens/riwayat/riwayat_penukaran_merchandise_screen.dart';

class PenukaranPoinScreen extends StatefulWidget {
  const PenukaranPoinScreen({super.key});

  @override
  _PenukaranPoinScreenState createState() => _PenukaranPoinScreenState();
}

class _PenukaranPoinScreenState extends State<PenukaranPoinScreen> {
  int poin = 0;
  double saldo = 0;
  List<Map<String, dynamic>> _merchandiseList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _selectedPoinTukarForLoading;
  int? _selectedMerchandiseIdForLoading;

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
    _loadAllData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initNotification() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future<void> _showSuccessNotification(
    int jumlahPoinDitukar,
    int saldoDidapatDariPenukaran,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'poin_channel_id_success_v3',
          'Penukaran Poin Sukses',
          channelDescription: 'Notifikasi untuk penukaran poin yang berhasil',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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
      print("Error showing success notification: $e");
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
      print("Error saving history to SharedPrefs: $e");
    }
  }

  Future<void> _showMerchandiseSuccessNotification(
    int jumlahPoinDitukar,
    String namaMerchandise,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'merch_channel_id_success_v1', // ID channel unik
          'Penukaran Merchandise Sukses',
          channelDescription:
              'Notifikasi untuk penukaran merchandise yang berhasil',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    try {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Penukaran Merchandise Berhasil!',
        'Anda menukar $jumlahPoinDitukar poin dengan $namaMerchandise.',
        notificationDetails,
      );
    } catch (e) {
      print("Error showing merchandise success notification: $e");
    }

    final notificationData = {
      'kegiatan': 'Tukar Poin dengan $namaMerchandise',
      'jenis': 'Penukaran Merchandise',
      'tanggal': DateTime.now().toIso8601String(),
      'poin': '-$jumlahPoinDitukar',
      'saldo': 'Rp 0',
    };
    try {
      await SharedPrefs.tambahRiwayat(notificationData);
    } catch (e) {
      print("Error saving merchandise history to SharedPrefs: $e");
    }
  }

  Future<void> _loadAllData() async {
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
        ApiService.getMerchandise(),
      ]);

      if (mounted) {
        final fetchedPoin =
            results[0] is int
                ? results[0] as int
                : int.tryParse(results[0].toString()) ?? poin;
        final fetchedSaldo =
            results[1] is num
                ? (results[1] as num).toDouble()
                : double.tryParse(results[1].toString()) ?? saldo;
        final fetchedMerchandise = results[2] as List<Map<String, dynamic>>;

        setState(() {
          poin = fetchedPoin;
          saldo = fetchedSaldo;
          _merchandiseList = fetchedMerchandise;
          _isLoading = false;
        });
        String? username = await SharedPrefs.getUsername();
        await SharedPrefs.saveUserData(userId, username ?? 'User', saldo, poin);
      }
    } catch (e) {
      if (mounted) {
        int localPoin = await SharedPrefs.getPoin();
        double localSaldo = await SharedPrefs.getSaldo();
        setState(() {
          _isLoading = false;
          poin = localPoin;
          saldo = localSaldo;
          _merchandiseList = [];
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
    if (_isSubmitting) return;
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      _selectedPoinTukarForLoading = jumlahPoinTukar;
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
                : int.tryParse(poinSisaRaw.toString()) ?? poin;
        final double saldoBaruServer =
            saldoSekarangRaw is num
                ? (saldoSekarangRaw).toDouble()
                : double.tryParse(saldoSekarangRaw.toString()) ?? saldo;
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedPoinTukarForLoading = null;
        });
      }
    }
  }

  void _handleTukarMerchandise({
    required int merchandiseId,
    required String merchandiseName,
    required int poinDibutuhkan,
  }) async {
    if (_isSubmitting) return;
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      _selectedMerchandiseIdForLoading = merchandiseId;
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
          _selectedMerchandiseIdForLoading = null;
        });
      }
      return;
    }

    if (poin < poinDibutuhkan) {
      _customDialog(
        context: context,
        title: "Poin Tidak Cukup",
        content:
            "Poin Anda ($poin) tidak mencukupi untuk menukar '$merchandiseName' yang membutuhkan $poinDibutuhkan poin.",
        confirmText: "OK",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange.shade700,
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedMerchandiseIdForLoading = null;
        });
      }
      return;
    }

    bool? confirm = await _customDialog(
      context: context,
      title: "Konfirmasi Penukaran",
      content:
          "Anda yakin ingin menukar $poinDibutuhkan poin dengan merchandise '$merchandiseName'?",
      confirmText: "Ya, Tukar",
      cancelText: "Batal",
      icon: Icons.card_giftcard_rounded,
      iconColor: Theme.of(context).primaryColor,
    );

    if (confirm == true) {
      try {
        final responseData = await ApiService.tukarPoinDenganMerchandise(
          userId: userId,
          merchandiseId: merchandiseId,
          poinDibutuhkan: poinDibutuhkan,
        );

        final dynamic poinSisaRaw = responseData['poin_tersisa'];
        if (poinSisaRaw == null) {
          throw Exception("Respons API tidak menyertakan 'poin_tersisa'.");
        }

        final int poinBaruServer =
            poinSisaRaw is int
                ? poinSisaRaw
                : int.tryParse(poinSisaRaw.toString()) ?? poin;

        if (mounted) {
          setState(() {
            poin = poinBaruServer;
          });
        }

        String? username = (await SharedPrefs.getUsername()) ?? 'User';
        await SharedPrefs.saveUserData(userId, username, saldo, poinBaruServer);

        _showMerchandiseSuccessNotification(poinDibutuhkan, merchandiseName);

        // --- MODIFIKASI DI SINI ---
        // Memberikan pesan yang lebih informatif sesuai alur baru
        _customDialog(
          context: context,
          title: "Pengajuan Berhasil",
          content:
              "Penukaran Anda untuk '$merchandiseName' telah diajukan. Silakan cek halaman 'Riwayat Penukaran' untuk melihat status dan mengambil barang jika sudah disetujui admin.",
          confirmText: "Mengerti",
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
          errorMessage = msg.replaceFirst('Exception: ', '');
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
            _selectedMerchandiseIdForLoading = null;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedMerchandiseIdForLoading = null;
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
      barrierDismissible: cancelText == null && onConfirm == null,
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
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
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

  Widget _buildInfoPanel(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color:
          isDarkMode ? theme.primaryColor.withOpacity(0.15) : theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Row(
          children: [
            // Bagian Poin
            Expanded(
              child: Column(
                children: [
                  Text(
                    "Poin Anda",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: customColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: Colors.orange.shade500,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        NumberFormat.decimalPattern('id_ID').format(poin),
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: customColors.titleTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Pemisah
            Container(
              height: 50,
              width: 1,
              color: theme.dividerColor,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            // Bagian Saldo
            Expanded(
              child: Column(
                children: [
                  Text(
                    "Total Saldo",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: customColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(saldo),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTukarOpsiItem({
    required BuildContext context,
    required int poinTukar,
    required int saldoTukar,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final bool canTukar = poin >= poinTukar;
    final bool isCurrentlySubmittingThisItem =
        _isSubmitting && _selectedPoinTukarForLoading == poinTukar;

    final Color accentColor = theme.primaryColor;

    Color tileColor =
        canTukar
            ? (isDarkMode
                ? accentColor.withOpacity(0.15)
                : accentColor.withOpacity(0.08))
            : theme.cardColor.withOpacity(isDarkMode ? 0.2 : 0.7);

    Color titleColor =
        canTukar ? customColors.titleTextColor! : theme.hintColor;
    Color subtitleColor =
        canTukar ? accentColor : theme.hintColor.withOpacity(0.8);

    return Card(
      elevation: canTukar ? 1.5 : 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              canTukar
                  ? accentColor.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      color: tileColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Tukar $poinTukar Poin",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: titleColor,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "Dapatkan ${currencyFormatter.format(saldoTukar)}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: subtitleColor,
            fontSize: 15,
          ),
        ),
        trailing:
            isCurrentlySubmittingThisItem
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
                : Icon(
                  canTukar
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline_rounded,
                  color:
                      canTukar ? accentColor : theme.hintColor.withOpacity(0.7),
                  size: 20,
                ),
        onTap:
            canTukar && !_isSubmitting
                ? () => _handleTukarPoin(poinTukar, saldoTukar)
                : null,
        splashColor: accentColor.withOpacity(0.2),
      ),
    );
  }

  Widget _buildMerchandiseOpsiItem({
    required BuildContext context,
    required Map<String, dynamic> merchandise,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final int id = merchandise['id'] ?? 0;
    final String name = merchandise['name'] ?? 'Merchandise Tidak Bernama';
    final int poinDibutuhkan = merchandise['point_cost'] ?? 0;
    final String? imageUrl = merchandise['image_url'];

    final bool canTukar = poin >= poinDibutuhkan;
    final bool isCurrentlySubmittingThisItem =
        _isSubmitting && _selectedMerchandiseIdForLoading == id;
    final Color accentColor = Colors.teal; // A different color for merchandise

    Color tileColor =
        canTukar
            ? (isDarkMode
                ? accentColor.withOpacity(0.15)
                : accentColor.withOpacity(0.08))
            : theme.cardColor.withOpacity(isDarkMode ? 0.2 : 0.7);
    Color titleColor =
        canTukar ? customColors.titleTextColor! : theme.hintColor;
    Color subtitleColor =
        canTukar ? accentColor : theme.hintColor.withOpacity(0.8);

    return Card(
      elevation: canTukar ? 1.5 : 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              canTukar
                  ? accentColor.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      color: tileColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor,
                            ),
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.card_giftcard,
                              color: Colors.grey.shade600,
                            ),
                          ),
                    )
                    : Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.card_giftcard,
                        color: Colors.grey.shade600,
                      ),
                    ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: titleColor,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Tukar ${NumberFormat.decimalPattern('id_ID').format(poinDibutuhkan)} Poin',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: subtitleColor,
            fontSize: 14,
          ),
        ),
        trailing:
            isCurrentlySubmittingThisItem
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
                : Icon(
                  canTukar
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline_rounded,
                  color:
                      canTukar ? accentColor : theme.hintColor.withOpacity(0.7),
                  size: 20,
                ),
        onTap:
            canTukar && !_isSubmitting
                ? () => _handleTukarMerchandise(
                  merchandiseId: id,
                  merchandiseName: name,
                  poinDibutuhkan: poinDibutuhkan,
                )
                : null,
        splashColor: accentColor.withOpacity(0.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- MODIFIKASI DIMULAI DI SINI ---
      appBar: AppBar(
        title: Text("Penukaran Poin"),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded),
            tooltip: 'Riwayat Penukaran Merchandise',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RiwayatPenukaranScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // --- MODIFIKASI SELESAI DI SINI ---
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : RefreshIndicator(
                onRefresh: _loadAllData,
                color: theme.primaryColor,
                backgroundColor: theme.cardColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoPanel(context),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          "Pilihan Penukaran Saldo",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: customColors.titleTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 10,
                        saldoTukar: 1000,
                      ),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 50,
                        saldoTukar: 5500,
                      ),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 100,
                        saldoTukar: 12000,
                      ),
                      _buildTukarOpsiItem(
                        context: context,
                        poinTukar: 200,
                        saldoTukar: 25000,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          "Tukar dengan Merchandise",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: customColors.titleTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_merchandiseList.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _merchandiseList.length,
                          itemBuilder: (context, index) {
                            final merchandise = _merchandiseList[index];
                            return _buildMerchandiseOpsiItem(
                              context: context,
                              merchandise: merchandise,
                            );
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30,
                            horizontal: 10,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Tidak ada merchandise yang tersedia untuk ditukar saat ini.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: customColors.secondaryTextColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
