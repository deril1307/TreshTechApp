// ignore_for_file: unused_field

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class WasteCategory {
  final int id;
  final String name;
  WasteCategory({required this.id, required this.name});
  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(id: json['id'], name: json['name']);
  }
}

class RequestPickupScreen extends StatefulWidget {
  final int userId;
  const RequestPickupScreen({super.key, required this.userId});

  @override
  State<RequestPickupScreen> createState() => _RequestPickupScreenState();
}

class _RequestPickupScreenState extends State<RequestPickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final String _apiBaseUrl = "https://web-apb.vercel.app";
  List<WasteCategory> _categories = [];
  WasteCategory? _selectedCategory;
  bool _isLoading = true;
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String _selectedAddress = "Mencari lokasi...";
  Marker? _selectedMarker;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchWasteCategories();
    await _determinePosition();
  }

  Future<void> _fetchWasteCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/waste-categories'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categories =
                data.map((json) => WasteCategory.fromJson(json)).toList();
          });
        }
      } else {
        throw Exception('Gagal memuat kategori');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Kategori: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // BARU: Fungsi untuk mendapatkan lokasi pengguna saat ini
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _selectedAddress = 'Layanan lokasi mati.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _selectedAddress = 'Izin lokasi ditolak.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _selectedAddress = 'Izin lokasi ditolak permanen.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      _currentPosition = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16),
      );
      _updateMarkerAndAddress(_currentPosition!);
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
      setState(() => _selectedAddress = "Gagal mendapatkan lokasi.");
    }
  }

  void _updateMarkerAndAddress(LatLng position) {
    setState(() {
      _selectedMarker = Marker(
        markerId: const MarkerId('selectedLocation'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Lokasi Jemput'),
      );
    });
    _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      if (mounted) {
        setState(() {
          _selectedAddress =
              "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
        });
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          _selectedAddress = "Gagal mendapatkan nama alamat.";
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap tentukan lokasi di peta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/api/pickup-requests'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': widget.userId,
            'waste_category_id': _selectedCategory!.id,
            'estimated_weight_g': int.parse(_weightController.text),
            'address': _selectedAddress,
            'latitude': _selectedMarker!.position.latitude,
            'longitude': _selectedMarker!.position.longitude,
          }),
        );
        Navigator.pop(context); // Tutup dialog loading
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan berhasil dikirim!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          final error = json.decode(response.body);
          throw Exception('Gagal mengirim permintaan: ${error['error']}');
        }
      } catch (e) {
        if (mounted)
          Navigator.pop(context); // Tutup dialog jika masih terbuka saat error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Permintaan Jemput")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: Column(
                  // Menggunakan Column agar peta tidak memenuhi layar
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<WasteCategory>(
                            value: _selectedCategory,
                            hint: const Text('Pilih Kategori Sampah'),
                            items:
                                _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Kategori harus dipilih'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Estimasi Berat (gram)',
                              hintText: 'Contoh: 500',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Berat tidak boleh kosong';
                              if (int.tryParse(value) == null)
                                return 'Masukkan angka bulat yang valid';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    // --- AREA PETA (DIUBAH TOTAL) ---
                    Expanded(
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target:
                                  _currentPosition ??
                                  const LatLng(
                                    -6.1751,
                                    106.8650,
                                  ), // Default ke Monas jika lokasi null
                              zoom: 15,
                            ),
                            onMapCreated:
                                (controller) => _mapController = controller,
                            markers: {
                              if (_selectedMarker != null) _selectedMarker!,
                            }, // Tampilkan marker
                            onTap: (LatLng position) {
                              _updateMarkerAndAddress(
                                position,
                              ); // Pindahkan marker saat di-tap
                            },
                          ),
                          // Tombol untuk kembali ke lokasi saat ini
                          Positioned(
                            bottom: 70,
                            right: 16,
                            child: FloatingActionButton.small(
                              onPressed: _determinePosition,
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tampilan Alamat dan Tombol Submit
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedAddress,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitRequest,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Kirim Permintaan'),
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
}
