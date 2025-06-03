// ignore_for_file: await_only_futures, unused_import, unnecessary_null_comparison, unnecessary_cast, deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';
import '../main.dart';

const String baseUrl = "http://10.0.2.2:5000";
// const String baseUrl = "https://e374-114-10-145-44.ngrok-free.app";

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final ValueNotifier<File?> _image = ValueNotifier<File?>(null);
  final ValueNotifier<String?> profilePictureUrl = ValueNotifier<String?>(null);
  late Future<void> _profileFuture;
  int userId = 0;
  bool isOffline = false;
  bool _isSaving =
      false; // State untuk loading saat menyimpan atau memuat data awal

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadUserIdAndProfile();
    _checkConnectivity(); // Cek konektivitas awal
    // Dengarkan perubahan konektivitas
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (mounted) {
        final newOfflineStatus = result.contains(ConnectivityResult.none);
        if (isOffline != newOfflineStatus) {
          // Hanya setState jika status berubah
          setState(() {
            isOffline = newOfflineStatus;
          });
        }
        if (!isOffline && userId != 0) {
          // Jika kembali online dan userId ada, coba muat ulang data profil
          // Ini bisa opsional, tergantung apakah Anda ingin otomatis refresh
          // _getProfileData();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    fullNameController.dispose();
    phoneNumberController.dispose();
    addressController.dispose();
    _image.dispose();
    profilePictureUrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        isOffline = connectivityResult.contains(ConnectivityResult.none);
      });
    }
  }

  Future<void> _loadUserIdAndProfile() async {
    if (mounted) setState(() => _isSaving = true); // Tampilkan loading awal
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString("user_id"); // Pastikan key konsisten
    if (storedUserId != null) {
      if (mounted) {
        userId = int.tryParse(storedUserId) ?? 0;
      }
      if (userId != 0) {
        await _getProfileData();
      } else {
        if (mounted) _showSnackbar("User ID tidak valid.", Colors.red);
      }
    } else {
      if (mounted) {
        _showSnackbar(
          "User ID tidak ditemukan. Silakan login kembali.",
          Colors.red,
        );
        // Pertimbangkan untuk navigasi kembali jika user ID tidak ada
        // Navigator.of(context).pop();
      }
    }
    if (mounted) setState(() => _isSaving = false); // Sembunyikan loading awal
  }

  Future<void> _getProfileData() async {
    if (userId == 0) return;
    if (isOffline) {
      if (mounted) {
        _showSnackbar(
          "Anda sedang offline. Menampilkan data tersimpan jika ada.",
          Theme.of(context).colorScheme.secondary,
        ); // Gunakan warna tema
      }
      // TODO: Implementasi memuat data profil dari SharedPreferences jika diperlukan
      return;
    }

    // Tidak perlu setState _isSaving true di sini jika sudah dihandle _loadUserIdAndProfile
    // atau jika ini dipanggil terpisah (misal saat refresh)
    // if (mounted) setState(() => _isSaving = true);

    try {
      var response = await Dio().get("$baseUrl/get-profile/$userId");
      if (response.statusCode == 200 && response.data["success"]) {
        var data = response.data["data"];
        if (mounted) {
          fullNameController.text = data["full_name"] ?? "";
          phoneNumberController.text = data["phone_number"] ?? "";
          addressController.text = data["address"] ?? "";
          profilePictureUrl.value = data["profile_picture"];
        }
      } else {
        if (mounted) {
          _showSnackbar(
            response.data["message"] ?? "Gagal memuat data profil.",
            Colors.orange,
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        _showSnackbar("Gagal memuat profil: ${e.message}", Colors.red);
      }
      print("Error getProfileData: $e");
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          "Terjadi kesalahan tidak dikenal saat memuat profil.",
          Colors.red,
        );
      }
      print("Error getProfileData (unknown): $e");
    } finally {
      // if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(BuildContext dialogContext) async {
    final ImagePicker picker = ImagePicker();
    final theme = Theme.of(dialogContext); // Gunakan context dari dialog
    final customColors = theme.extension<CustomThemeColors>()!;

    final pickedFileSource = await showDialog<ImageSource>(
      context: dialogContext, // Gunakan context yang di-pass untuk dialog
      builder:
          (context) => AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Pilih Sumber Gambar",
              style: TextStyle(color: customColors.titleTextColor),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
                child: Text(
                  "Kamera",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
                child: Text(
                  "Galeri",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (pickedFileSource != null) {
      final XFile? file = await picker.pickImage(
        source: pickedFileSource,
        imageQuality: 70,
      ); // Tambah imageQuality
      if (file != null) {
        if (mounted) {
          _image.value = File(file.path);
          profilePictureUrl.value =
              null; // Hapus URL lama jika gambar baru dipilih
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Harap perbaiki data yang salah.", Colors.orange);
      return;
    }

    if (userId == 0) {
      _showSnackbar(
        "User ID tidak ditemukan. Silakan login kembali.",
        Colors.red,
      );
      return;
    }

    if (isOffline) {
      _showSnackbar(
        "Anda sedang offline. Tidak dapat menyimpan perubahan.",
        Colors.orange,
      );
      return;
    }

    if (mounted) setState(() => _isSaving = true);

    try {
      String? fileName = _image.value?.path.split('/').last;
      var formData = FormData.fromMap({
        "user_id": userId.toString(),
        "full_name": fullNameController.text,
        "phone_number": phoneNumberController.text,
        "address": addressController.text,
        if (_image.value != null)
          "profile_picture": await MultipartFile.fromFile(
            _image.value!.path,
            filename: fileName,
          ),
      });

      var response = await Dio().put("$baseUrl/update-profile", data: formData);

      if (response.statusCode == 200 &&
          response.data["message"] == "✅ Profil berhasil diperbarui!") {
        _showSnackbar(
          "Profil berhasil diperbarui!",
          Theme.of(context).primaryColor,
        );
        await Future.delayed(
          const Duration(milliseconds: 1500),
        ); // Beri waktu snackbar terlihat
        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Kirim true untuk menandakan ada perubahan ke ProfileScreen
        }
      } else {
        _showSnackbar(
          response.data["message"] ?? "Gagal memperbarui profil.",
          Colors.red,
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Terjadi kesalahan jaringan.";
      if (e.response != null &&
          e.response!.data != null &&
          e.response!.data["message"] != null) {
        errorMessage = e.response!.data["message"];
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Koneksi timeout. Silakan coba lagi.";
      } else if (e.error is SocketException) {
        // Lebih spesifik untuk SocketException
        errorMessage =
            "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.";
      }
      _showSnackbar(errorMessage, Colors.red);
      print("DioError updating profile: $e");
    } catch (e) {
      _showSnackbar(
        "Terjadi kesalahan tidak dikenal: ${e.toString()}",
        Colors.red,
      );
      print("Update profile error (unknown): $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    // ignore: unused_local_variable
    final theme = Theme.of(context);
    final bool isError = color == Colors.red || color == Colors.orange;
    final SnackBarBehavior behavior = SnackBarBehavior.floating;
    final EdgeInsets margin = const EdgeInsets.fromLTRB(15, 5, 15, 10);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.5),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: behavior,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: margin,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Edit Profil",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        // backgroundColor dan iconTheme diambil dari AppBarTheme di main.dart
      ),
      body: FutureBuilder<void>(
        future: _profileFuture, // Future untuk memuat data awal
        builder: (context, snapshot) {
          // Tampilkan loading utama hanya saat _profileFuture berjalan DAN controller kosong
          if (snapshot.connectionState == ConnectionState.waiting &&
              fullNameController.text.isEmpty &&
              !_isSaving) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }
          // Jika ada error saat memuat data awal (misal user ID tidak ada)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat data: ${snapshot.error}",
                style: TextStyle(color: customColors.secondaryTextColor),
              ),
            );
          }

          // Selalu tampilkan form setelah loading awal selesai atau jika sudah ada data di controller
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch, // Agar tombol full width
                    children: [
                      if (isOffline) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withOpacity(
                              0.2,
                            ), // Warna dari tema error
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Anda sedang offline",
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ValueListenableBuilder<File?>(
                              valueListenable: _image,
                              builder: (context, imageFile, child) {
                                return ValueListenableBuilder<String?>(
                                  valueListenable: profilePictureUrl,
                                  builder: (context, url, child) {
                                    ImageProvider? backgroundImage;
                                    Widget? placeholderChild;

                                    if (imageFile != null) {
                                      backgroundImage = FileImage(imageFile);
                                    } else if (url != null && url.isNotEmpty) {
                                      backgroundImage =
                                          CachedNetworkImageProvider(url);
                                    } else {
                                      // Jika tidak ada gambar sama sekali, gunakan ikon placeholder
                                      placeholderChild = Icon(
                                        Icons.person_outline_rounded,
                                        size: 60,
                                        color: theme.hintColor.withOpacity(0.6),
                                      );
                                      // backgroundImage tetap null agar CircleAvatar menggunakan backgroundColor
                                    }
                                    return CircleAvatar(
                                      radius: 65, // Sedikit lebih besar
                                      backgroundColor:
                                          theme
                                              .cardColor, // Warna background jika tidak ada gambar
                                      backgroundImage: backgroundImage,
                                      child: placeholderChild,
                                    );
                                  },
                                );
                              },
                            ),
                            Material(
                              // Untuk efek ripple pada tombol kamera
                              color: theme.primaryColor,
                              shape: const CircleBorder(),
                              elevation: 2.0,
                              child: InkWell(
                                onTap: () => _pickImage(context),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30), // Spasi lebih banyak
                      _buildValidatedTextField(
                        context: context,
                        controller: fullNameController,
                        label: "Nama Lengkap",
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Nama tidak boleh kosong";
                          }
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                            return "Nama hanya boleh huruf dan spasi";
                          }
                          return null;
                        },
                      ),
                      _buildValidatedTextField(
                        context: context,
                        controller: phoneNumberController,
                        label: "Nomor Telepon",
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Nomor telepon tidak boleh kosong";
                          }
                          if (!RegExp(r'^\d+$').hasMatch(value)) {
                            return "Nomor hanya boleh angka";
                          }
                          if (value.length < 10 || value.length > 15) {
                            return "Nomor telepon harus antara 10-15 digit";
                          }
                          return null;
                        },
                      ),
                      _buildValidatedTextField(
                        context: context,
                        controller: addressController,
                        label: "Alamat",
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Alamat tidak boleh kosong";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        icon:
                            _isSaving
                                ? const SizedBox.shrink() // Jangan tampilkan ikon jika sedang loading
                                : const Icon(Icons.save_outlined, size: 20),
                        label:
                            _isSaving
                                ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme
                                          .colorScheme
                                          .onPrimary, // Warna loading indicator pada tombol
                                    ),
                                  ),
                                )
                                : Text(
                                  "Simpan Perubahan",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        onPressed: _isSaving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor:
                              theme
                                  .colorScheme
                                  .onPrimary, // Warna teks dan ikon pada tombol
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Sesuaikan radius
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ), // Padding lebih besar
                          minimumSize: const Size(
                            double.infinity,
                            52,
                          ), // Tinggi tombol
                          elevation: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Overlay loading saat proses _updateProfile atau _loadUserData sedang berjalan (setelah loading awal)
              if (_isSaving &&
                  !(snapshot.connectionState == ConnectionState.waiting &&
                      fullNameController.text.isEmpty))
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildValidatedTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ), // Kurangi padding vertikal
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: customColors.bodyTextColor, fontSize: 15.5),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: customColors.secondaryTextColor,
            fontSize: 15,
          ),
          hintText: "Masukkan $label",
          hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.7)),
          prefixIcon:
              prefixIcon != null
                  ? Icon(
                    prefixIcon,
                    color: theme.primaryColor.withOpacity(0.8),
                    size: 22,
                  )
                  : null,
          filled: true,
          fillColor: theme.cardColor, // Background field lebih netral
          border: OutlineInputBorder(
            // Border default
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.dividerColor.withOpacity(0.8),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primaryColor, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
