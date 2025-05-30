import 'dart:async'; // Diperlukan untuk Future BitmapDescriptor
import 'dart:typed_data'; // Diperlukan untuk ByteData
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Diperlukan untuk rootBundle
import 'dart:ui' as ui; // Diperlukan untuk ui.Codec

import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/services/api_service.dart';

class TempatSampah {
  final String id;
  final String nama;
  final LatLng posisi;
  final String deskripsi;

  TempatSampah({
    required this.id,
    required this.nama,
    required this.posisi,
    required this.deskripsi,
  });
}

class SetorSampahScreen extends StatefulWidget {
  const SetorSampahScreen({super.key});
  @override
  _SetorSampahScreenState createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  final _beratController = TextEditingController();
  Map<String, dynamic>? _selectedKategoriSampahApi;
  late Future<List<dynamic>> _kategoriSampahApiFuture;

  TempatSampah? _selectedTempatSampah;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  BitmapDescriptor? _trashCanIcon; // Untuk ikon kustom
  BitmapDescriptor? _selectedTrashCanIcon; // Untuk ikon kustom yang terpilih

  // --- LOKASI DUMMY AREA BOJONGSOANG ---
  final List<TempatSampah> _daftarTempatSampahDummy = [
    TempatSampah(
      id: 'ts_bjs_001',
      nama: 'TPS Griya Bandung Asri 1',
      posisi: const LatLng(-6.9788, 107.6305),
      deskripsi: 'Dekat gerbang utama GBA 1',
    ),
    TempatSampah(
      id: 'ts_bjs_002',
      nama: 'Bank Sampah Buah Batu Square',
      posisi: const LatLng(-6.9720, 107.6340),
      deskripsi: 'Area parkir belakang Transmart Buah Batu',
    ),
    TempatSampah(
      id: 'ts_bjs_003',
      nama: 'TPS Terpadu Cijagra',
      posisi: const LatLng(-6.9685, 107.6280),
      deskripsi: 'Jl. Cijagra, Bojongsoang',
    ),
    TempatSampah(
      id: 'ts_bjs_004',
      nama: 'TPS Desa Lengkong',
      posisi: const LatLng(-6.9850, 107.6380),
      deskripsi: 'Dekat kantor Desa Lengkong, Bojongsoang',
    ),
    TempatSampah(
      id: 'ts_bjs_005',
      nama: 'TPS Podomoro Park',
      posisi: const LatLng(-6.9650, 107.6450),
      deskripsi: 'Area fasilitas umum Podomoro Park',
    ),
  ];

  static const LatLng _initialCameraPosition = LatLng(
    -6.9750,
    107.6350,
  ); // Pusat area Bojongsoang (kira-kira)

  final InputDecoration _inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color.fromARGB(255, 7, 168, 13),
        width: 2,
      ),
    ),
    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
  );

  @override
  void initState() {
    super.initState();
    _kategoriSampahApiFuture = ApiService.getKategoriSampah();
    _loadCustomMarkers(); // Memuat ikon kustom lalu generate marker
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<void> _loadCustomMarkers() async {
    // Ganti 'assets/icons/trash_can_marker.png' dengan path aset Anda
    // Ganti 'assets/icons/selected_trash_can_marker.png' jika punya ikon berbeda untuk yg terpilih
    try {
      final Uint8List iconData = await getBytesFromAsset(
        'assets/icons/trash_can_marker.png',
        100,
      ); // 100 adalah lebar dalam piksel
      _trashCanIcon = BitmapDescriptor.fromBytes(iconData);

      // Jika Anda punya ikon berbeda untuk marker yang terpilih:
      // final Uint8List selectedIconData = await getBytesFromAsset('assets/icons/selected_trash_can_marker.png', 120);
      // _selectedTrashCanIcon = BitmapDescriptor.fromBytes(selectedIconData);
      // Atau gunakan warna default jika tidak ada ikon khusus terpilih
      _selectedTrashCanIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    } catch (e) {
      print("Error loading custom marker icons: $e");
      // Fallback ke default jika ikon kustom gagal dimuat
      _trashCanIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      _selectedTrashCanIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    }
    _generateMarkers();
  }

  void _generateMarkers() {
    if (_trashCanIcon == null || _selectedTrashCanIcon == null) {
      // Jika ikon belum siap, tunggu atau gunakan default (seharusnya sudah ditangani di _loadCustomMarkers)
      print("Ikon kustom belum siap, menggunakan default sementara.");
    }

    Set<Marker> tempMarkers = {};
    for (var tempat in _daftarTempatSampahDummy) {
      final bool isSelected = _selectedTempatSampah?.id == tempat.id;
      tempMarkers.add(
        Marker(
          markerId: MarkerId(tempat.id),
          position: tempat.posisi,
          infoWindow: InfoWindow(title: tempat.nama, snippet: tempat.deskripsi),
          icon:
              isSelected
                  ? (_selectedTrashCanIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ))
                  : (_trashCanIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      )),
          onTap: () {
            if (mounted) {
              setState(() {
                _selectedTempatSampah = tempat;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(tempat.posisi, 16),
                );
                _generateMarkers();
              });
            }
          },
        ),
      );
    }
    if (mounted) {
      setState(() {
        _markers = tempMarkers;
      });
    }
  }

  void _submitData() async {
    final beratGram = int.tryParse(_beratController.text) ?? 0;

    if (_selectedKategoriSampahApi == null || beratGram <= 0) {
      _showDialog(
        "Input tidak valid",
        "Pilih jenis sampah dan masukkan berat sampah dengan benar.",
      );
      return;
    }
    if (_selectedTempatSampah == null) {
      _showDialog(
        "Lokasi Belum Dipilih",
        "Silakan pilih salah satu tempat sampah di peta.",
      );
      return;
    }

    final jenis = _selectedKategoriSampahApi!['name'] ?? 'Tidak diketahui';
    final dynamic poinPerUnitDynamic =
        _selectedKategoriSampahApi!['point_per_unit'];
    final double poinPerKg =
        (poinPerUnitDynamic is String)
            ? (double.tryParse(poinPerUnitDynamic) ?? 0.0)
            : (poinPerUnitDynamic as num?)?.toDouble() ?? 0.0;
    final String unit =
        (_selectedKategoriSampahApi!['unit'] as String?) ?? 'kg';

    final beratKg = beratGram / 1000;
    final poinDidapat = (beratKg * poinPerKg).round();
    final totalPoinLama = await SharedPrefs.getPoin();
    final totalPoinBaru = totalPoinLama + poinDidapat;
    final userId = await SharedPrefs.getUserId();

    if (userId == null) {
      _showDialog("Error", "User ID tidak ditemukan. Mohon login ulang.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text("Memproses data..."),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final response = await ApiService.setorSampah(
        int.parse(userId),
        _selectedKategoriSampahApi!['id'],
        beratGram,
        _selectedTempatSampah!.posisi.latitude,
        _selectedTempatSampah!.posisi.longitude,
      );

      if (mounted) Navigator.pop(context);

      if (response.containsKey('points_earned')) {
        await SharedPrefs.savePoin(totalPoinBaru);
        _showDialog(
          "Berhasil",
          "Setor $beratGram gram (${beratKg.toStringAsFixed(2)} $unit) $jenis.\nLokasi: ${_selectedTempatSampah!.nama}\nKamu dapat ${response['points_earned']} poin!\nTotal poin sekarang: $totalPoinBaru",
          isSuccess: true,
        );
        _beratController.clear();
        if (mounted) {
          setState(() {
            _selectedKategoriSampahApi = null;
            _selectedTempatSampah = null;
            _generateMarkers();
          });
        }
      } else {
        _showDialog(
          "Gagal",
          response['message'] ?? "Terjadi kesalahan saat setor sampah.",
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showDialog(
        "Error",
        "Tidak dapat terhubung ke server.\nDetail: ${e.toString()}",
      );
    }
  }

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
              size: 48,
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showKategoriDialog() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8.0,
                    ),
                    child: Text(
                      "Pilih Kategori Sampah",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: _kategoriSampahApiFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green,
                            ),
                          );
                        if (snapshot.hasError)
                          return Center(
                            child: Text(
                              'Gagal memuat kategori: ${snapshot.error}',
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        if (!snapshot.hasData || snapshot.data!.isEmpty)
                          return Center(
                            child: Text(
                              'Tidak ada kategori sampah',
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        final kategoriList = snapshot.data!;
                        return ListView.builder(
                          controller: scrollController,
                          itemCount: kategoriList.length,
                          itemBuilder: (ctx, index) {
                            final kategori = kategoriList[index];
                            final bool isSelected =
                                _selectedKategoriSampahApi != null &&
                                _selectedKategoriSampahApi!['id'] ==
                                    kategori['id'];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      _selectedKategoriSampahApi = kategori;
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.white,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.green
                                              : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          kategori['name'] ??
                                              'Nama Tidak Tersedia',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color:
                                                isSelected
                                                    ? Colors.green.shade700
                                                    : Colors.black87,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                        )
                                      else
                                        Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.grey.shade400,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Setor Sampah",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pilih Jenis Sampah",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showKategoriDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedKategoriSampahApi == null
                              ? 'Ketuk untuk memilih...'
                              : (_selectedKategoriSampahApi!['name'] ??
                                  'Nama Tidak Tersedia'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color:
                                _selectedKategoriSampahApi == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.grey.shade700,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Berat Sampah (gram)",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _beratController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                decoration: _inputDecoration.copyWith(
                  hintText: "Contoh: 500",
                  prefixIcon: Icon(
                    Icons.scale_outlined,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Pilih Tempat Sampah Terdekat",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      if (mounted) {
                        _mapController = controller;
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _initialCameraPosition,
                      zoom: 14.5,
                    ), // Zoom sedikit lebih dekat
                    markers: _markers,
                    mapType: MapType.normal,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                ),
              ),
              if (_selectedTempatSampah != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Card(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.recycling_rounded,
                        color: Colors.green.shade700,
                        size: 32,
                      ),
                      title: Text(
                        _selectedTempatSampah!.nama,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        _selectedTempatSampah!.deskripsi,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      tileColor: Colors.green.withOpacity(0.05),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      "Setor Sekarang",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
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
