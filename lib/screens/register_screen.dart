import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahkan import
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key}); // Tambahkan const dan Key

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();

  bool isLoading = false;
  bool _passwordVisible = false; // Untuk toggle visibilitas password

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  // Fungsi validasi email
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final fullName = fullNameController.text.trim();
    final password = passwordController.text;

    // Validasi input dasar
    if (fullName.isEmpty) {
      _showSnackBar("Nama Lengkap belum diisi", isError: true);
      return;
    }
    if (username.isEmpty) {
      _showSnackBar("Username belum diisi", isError: true);
      return;
    }
    if (email.isEmpty) {
      _showSnackBar("Email belum diisi", isError: true);
      return;
    }
    if (!isValidEmail(email)) {
      _showSnackBar(
        "Format email tidak valid. Contoh: user@example.com",
        isError: true,
      );
      return;
    }
    if (password.isEmpty) {
      _showSnackBar("Password belum diisi", isError: true);
      return;
    }
    if (password.length < 6) {
      // Contoh validasi panjang password
      _showSnackBar("Password minimal harus 6 karakter", isError: true);
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.register(
      username,
      email,
      password,
      fullName,
    );

    if (!mounted) return; // Periksa mounted state sebelum setState
    setState(() => isLoading = false);

    if (response["message"] == "Registrasi berhasil!") {
      _showSnackBar("Registrasi berhasil! Silakan login.", isError: false);
      await Future.delayed(
        const Duration(milliseconds: 1500),
      ); // Beri waktu SnackBar terlihat
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        // Ganti agar tidak bisa kembali ke register
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false, // Hapus semua route sebelumnya
      );
    } else {
      _showSnackBar(
        response["message"] ?? "Terjadi kesalahan saat registrasi.",
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
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
        hintText: 'Masukkan $labelText', // Tambahkan hint text
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.green.shade600,
          size: 22,
        ), // Ukuran ikon disesuaikan
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white, // Latar belakang field putih
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

    // Atur warna status bar agar konsisten dengan AppBar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.green.shade600, // Samakan dengan AppBar
        statusBarIconBrightness:
            Brightness.light, // Ikon terang jika background gelap
      ),
    );

    return Scaffold(
      backgroundColor: Colors.green.shade50, // Latar belakang utama
      appBar: AppBar(
        backgroundColor:
            Colors.green.shade600, // Warna AppBar yang lebih menonjol
        elevation: 2, // Sedikit shadow
        title: Text(
          "Buat Akun Baru", // Judul lebih deskriptif
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Ikon kembali putih
        leading: IconButton(
          // Tombol kembali kustom jika diperlukan
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gambar Header
                Image.asset(
                  "assets/TrashTech.png",
                  height: 100,
                  width: 100,
                ), // Ukuran disesuaikan
                const SizedBox(height: 16),
                Text(
                  "Daftarkan Diri Anda",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  "Isi data di bawah untuk membuat akun baru.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 28),

                // Form Registrasi
                TextField(
                  controller: fullNameController,
                  style: GoogleFonts.poppins(),
                  decoration: themedInputDecoration(
                    labelText: "Nama Lengkap",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: usernameController,
                  style: GoogleFonts.poppins(),
                  decoration: themedInputDecoration(
                    labelText: "Username",
                    prefixIcon: Icons.account_circle_outlined,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailController,
                  style: GoogleFonts.poppins(),
                  decoration: themedInputDecoration(
                    labelText: "Email",
                    prefixIcon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 28),

                // Tombol Register
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.green.shade600,
                      ),
                    )
                    : ElevatedButton.icon(
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sudah punya akun?",
                      style: GoogleFonts.poppins(color: Colors.grey.shade700),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          // Ganti agar tidak bisa kembali ke register
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                      ),
                      child: Text(
                        "Login di sini",
                        style: GoogleFonts.poppins(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Tambahan padding di bawah
              ],
            ),
          ),
        ),
      ),
    );
  }
}
