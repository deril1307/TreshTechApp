import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:intl/intl.dart';

class RiwayatItem {
  final String judul;
  final String jenis;
  final DateTime tanggal;
  final Map<String, String> detail;
  final bool isLocal;
  final int? originalIndex;
  final int? serverId;
  final String? status;

  RiwayatItem({
    required this.judul,
    required this.jenis,
    required this.tanggal,
    required this.detail,
    this.isLocal = false,
    this.originalIndex,
    this.serverId,
    this.status,
  });
}

class RiwayatScreen extends StatefulWidget {
  @override
  _RiwayatScreenState createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<RiwayatItem> _riwayatGabungan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllHistory();
  }

  Future<void> _loadAllHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    String? userId = await SharedPrefs.getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    List<RiwayatItem> combinedList = [];
    final List<Map<String, String>> localHistory = SharedPrefs.getRiwayat();
    for (int i = 0; i < localHistory.length; i++) {
      var item = localHistory[i];
      combinedList.add(
        RiwayatItem(
          judul: item['kegiatan'] ?? 'Aktivitas',
          jenis: item['jenis'] ?? 'Lainnya',
          tanggal: DateTime.tryParse(item['tanggal'] ?? '') ?? DateTime.now(),
          detail: {'Poin': item['poin'] ?? '-', 'Saldo': item['saldo'] ?? '-'},
          isLocal: true,
          originalIndex: i,
        ),
      );
    }
    try {
      final List<dynamic> pickupHistory =
          await ApiService.fetchUserPickupHistory(userId);
      for (var item in pickupHistory) {
        combinedList.add(
          RiwayatItem(
            judul: "Permintaan Jemput",
            jenis: "Jemput Sampah",
            tanggal:
                DateTime.tryParse(item['request_date'] ?? '') ?? DateTime.now(),
            detail: {
              'ID Permintaan': item['id'].toString(),
              'Jenis Sampah': item['waste_category_name'] ?? '-',
              'Estimasi Berat': "${item['estimated_weight_g']} g",
              'Alamat': item['address'] ?? '-',
              'Status': item['status']?.replaceAll('_', ' ') ?? '-',
            },
            isLocal: false,
            serverId: item['id'],
            status: item['status'],
          ),
        );
      }
    } catch (e) {
      print("Error memuat riwayat jemput: $e");
    }
    combinedList.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    if (mounted) {
      setState(() {
        _riwayatGabungan = combinedList;
        _isLoading = false;
      });
    }
  }

  IconData getIconByJenis(String jenis) {
    String lowerJenis = jenis.toLowerCase();
    if (lowerJenis.contains('jemput sampah')) return Icons.local_shipping;
    return Icons.history;
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title, style: GoogleFonts.poppins()),
          content: Text(content, style: GoogleFonts.poppins()),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: GoogleFonts.poppins()),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(
                confirmText,
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleAction(RiwayatItem item) {
    if (item.isLocal) {
      // Aksi untuk riwayat lokal -> Hapus dari HP
      _showConfirmationDialog(
        title: 'Hapus Riwayat Lokal',
        content: 'Anda yakin ingin menghapus riwayat ini dari HP Anda?',
        confirmText: 'Hapus',
        onConfirm: () async {
          await SharedPrefs.hapusRiwayatByIndex(item.originalIndex!);
          _loadAllHistory();
        },
      );
    } else {
      // Aksi untuk riwayat dari server
      if (item.status == 'SELESAI') {
        // Aksi untuk status Selesai -> Hapus Permanen
        _showConfirmationDialog(
          title: 'Hapus Riwayat Permanen',
          content:
              'PERINGATAN: Anda akan menghapus riwayat ini secara permanen dari server. Tindakan ini tidak dapat dibatalkan.',
          confirmText: 'Ya, Hapus Permanen',
          onConfirm: () async {
            try {
              await ApiService.deletePickupHistory(item.serverId!);
            } catch (e) {
              // handle error
            }
            _loadAllHistory();
          },
        );
      } else {
        // Aksi untuk status lain (Menunggu, Diproses) -> Batalkan
        _showConfirmationDialog(
          title: 'Batalkan Penjemputan',
          content: 'Anda yakin ingin membatalkan permintaan penjemputan ini?',
          confirmText: 'Ya, Batalkan',
          onConfirm: () async {
            try {
              await ApiService.updatePickupStatus(item.serverId!, 'DIBATALKAN');
            } catch (e) {
              // handle error
            }
            _loadAllHistory();
          },
        );
      }
    }
  }

  void _clearAllHistory() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Aktivitas", style: GoogleFonts.poppins()),
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Hapus Semua Riwayat Lokal',
            onPressed: _clearAllHistory,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _riwayatGabungan.isEmpty
              ? Center(
                child: Text(
                  "Belum ada riwayat.",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAllHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _riwayatGabungan.length,
                  itemBuilder: (context, index) {
                    final item = _riwayatGabungan[index];
                    final formattedDate = DateFormat(
                      'dd MMM kk:mm',
                      'id_ID',
                    ).format(item.tanggal);

                    // DIUBAH TOTAL: Logika untuk menentukan tombol aksi
                    Widget? actionButton;
                    IconData actionIcon = Icons.help; // Default icon
                    String actionTooltip = '';
                    Color actionColor = Colors.grey;

                    if (item.isLocal) {
                      actionIcon = Icons.delete_outline;
                      actionTooltip = 'Hapus Riwayat Lokal';
                      actionColor = Colors.red.shade400;
                      actionButton = IconButton(
                        icon: Icon(actionIcon, color: actionColor),
                        tooltip: actionTooltip,
                        onPressed: () => _handleAction(item),
                      );
                    } else {
                      bool isCancellable =
                          item.status == 'MENUNGGU_KONFIRMASI' ||
                          item.status == 'DIPROSES';
                      bool isCompleted = item.status == 'SELESAI';

                      if (isCancellable) {
                        actionIcon = Icons.cancel_outlined;
                        actionTooltip = 'Batalkan Penjemputan';
                        actionColor = Colors.orange.shade800;
                        actionButton = IconButton(
                          icon: Icon(actionIcon, color: actionColor),
                          tooltip: actionTooltip,
                          onPressed: () => _handleAction(item),
                        );
                      } else if (isCompleted) {
                        actionIcon = Icons.delete_forever_outlined;
                        actionTooltip = 'Hapus Riwayat Permanen';
                        actionColor = Colors.red.shade700;
                        actionButton = IconButton(
                          icon: Icon(actionIcon, color: actionColor),
                          tooltip: actionTooltip,
                          onPressed: () => _handleAction(item),
                        );
                      }
                    }

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
                            getIconByJenis(item.jenis),
                            color: Colors.green.shade800,
                          ),
                        ),
                        title: Text(
                          item.judul,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          formattedDate,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                ...item.detail.entries
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${entry.key}: ",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                entry.value,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                if (actionButton != null)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: actionButton,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
