import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahkan import
import 'package:tubes_mobile/screens/register_screen.dart';
import 'package:tubes_mobile/screens/requestreset_screen.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/screens/home_screen.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _passwordVisible = false; // Untuk toggle visibilitas password

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  Future<void> loginUser() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty) {
      _showSnackBar("Email atau Username belum diisi");
      return;
    }

    if (password.isEmpty) {
      _showSnackBar("Password belum diisi");
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.login(identifier, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response["message"] == "Login berhasil!") {
      await SharedPrefs.saveUserId(response["user_id"].toString());

      if (!mounted) return;

      _showSuccessDialog("Login berhasil!");

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ), // Tambahkan const
      );
    } else {
      _showSnackBar(response["message"] ?? "Terjadi kesalahan saat login.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green.shade600,
              size: 48,
            ),
            title: Text(
              "Sukses",
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
            // Tidak ada actions karena dialog akan hilang otomatis
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan InputDecoration yang konsisten
    InputDecoration themedInputDecoration({
      required String labelText,
      required IconData prefixIcon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
        prefixIcon: Icon(prefixIcon, color: Colors.green.shade600),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          Colors.green.shade50, // Latar belakang sedikit lebih hijau
      body: SafeArea(
        // Gunakan SafeArea
        child: Center(
          child: SingleChildScrollView(
            // Agar bisa di-scroll jika konten melebihi layar
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ), // Padding lebih besar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Agar tombol bisa full-width
              children: [
                Image.asset(
                  'assets/TrashTech.png',
                  width: 130,
                  height: 130,
                ), // Ukuran sedikit disesuaikan
                const SizedBox(height: 24),
                Text(
                  "Selamat Datang!", // Teks sapaan lebih ramah
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26, // Ukuran font disesuaikan
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  "Login untuk melanjutkan ke TrashTech",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: identifierController,
                  style: GoogleFonts.poppins(),
                  keyboardType: TextInputType.emailAddress,
                  decoration: themedInputDecoration(
                    labelText: "Email atau Username",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  style: GoogleFonts.poppins(),
                  obscureText: !_passwordVisible,
                  decoration: themedInputDecoration(
                    labelText: "Password",
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestResetScreen(),
                          ), // Tambahkan const
                        ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      "Lupa password?",
                      style: GoogleFonts.poppins(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.green.shade600,
                      ),
                    )
                    : ElevatedButton.icon(
                      // Tombol dengan ikon
                      icon: const Icon(
                        Icons.login_rounded,
                        color: Colors.white,
                      ),
                      onPressed: loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ), // Padding vertikal
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      label: Text(
                        "Login",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600, // Lebih tebal
                          color: Colors.white,
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                Row(
                  // Untuk link register
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun?",
                      style: GoogleFonts.poppins(color: Colors.grey.shade700),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(),
                            ), // Tambahkan const
                          ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                      ),
                      child: Text(
                        "Register di sini",
                        style: GoogleFonts.poppins(
                          color: Colors.green.shade700, // Warna konsisten
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
