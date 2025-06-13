// ignore_for_file: await_only_futures, unused_import, duplicate_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/screens/loginAndRegist/login_screen.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    super.dispose();
  }

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
    // ignore: unused_local_variable
    final theme = Theme.of(context); // Ambil theme untuk snackbar

    if (fullName.isEmpty) {
      _showSnackBar(
        "Nama Lengkap belum diisi",
        isError: true,
        context: context,
      );
      return;
    }
    if (username.isEmpty) {
      _showSnackBar("Username belum diisi", isError: true, context: context);
      return;
    }
    if (email.isEmpty) {
      _showSnackBar("Email belum diisi", isError: true, context: context);
      return;
    }
    if (!isValidEmail(email)) {
      _showSnackBar(
        "Format email tidak valid. Contoh: user@example.com",
        isError: true,
        context: context,
      );
      return;
    }
    if (password.isEmpty) {
      _showSnackBar("Password belum diisi", isError: true, context: context);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(
        "Password minimal harus 6 karakter",
        isError: true,
        context: context,
      );
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    final response = await ApiService.register(
      username,
      email,
      password,
      fullName,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response["message"] == "Registrasi berhasil!") {
      _showSnackBar(
        "Registrasi berhasil! Silakan login.",
        isError: false,
        context: context,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      _showSnackBar(
        response["message"] ?? "Terjadi kesalahan saat registrasi.",
        isError: true,
        context: context,
      );
    }
  }

  void _showSnackBar(
    String message, {
    required bool isError,
    required BuildContext context,
  }) {
    if (!mounted) return;
    final theme = Theme.of(context); // Ambil theme dari context yang di-pass
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: isError ? theme.colorScheme.onError : Colors.white,
          ),
        ),
        backgroundColor:
            isError
                ? theme.colorScheme.error
                : theme.primaryColor, // Warna snackbar dari tema
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    InputDecoration themedInputDecoration({
      required String labelText,
      required IconData prefixIcon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(
          color: customColors.secondaryTextColor,
          fontSize: 15,
        ),
        hintText: 'Masukkan $labelText',
        hintStyle: GoogleFonts.poppins(
          color: theme.hintColor.withOpacity(0.7),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: theme.primaryColor.withOpacity(0.8),
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.cardColor.withOpacity(
          theme.brightness == Brightness.light ? 0.8 : 0.2,
        ),
        border: OutlineInputBorder(
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
          vertical: 16,
          horizontal: 20,
        ),
      );
    }

    // Atur warna status bar agar konsisten dengan AppBar
    // Ini sebaiknya dilakukan sekali di MaterialApp atau saat tema berubah jika memungkinkan
    // Namun, jika hanya untuk halaman ini, bisa diletakkan di sini.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor:
            theme.appBarTheme.backgroundColor ??
            theme.primaryColor, // Warna dari AppBarTheme
        statusBarIconBrightness:
            theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // backgroundColor, elevation, titleTextStyle, iconTheme diambil dari AppBarTheme di main.dart
        title: Text(
          "Buat Akun Baru",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ), // Style judul dari AppBarTheme
        ),
        leading: IconButton(
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
                Image.asset(
                  "assets/TrashTech.png", // Pastikan path aset benar
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  "Daftarkan Diri Anda",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26, // Ukuran disesuaikan
                    fontWeight: FontWeight.bold,
                    color: customColors.titleTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Isi data di bawah untuk membuat akun baru.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15, // Ukuran disesuaikan
                    color: customColors.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: fullNameController,
                  style: GoogleFonts.poppins(
                    color: customColors.bodyTextColor,
                    fontSize: 15.5,
                  ),
                  decoration: themedInputDecoration(
                    labelText: "Nama Lengkap",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  style: GoogleFonts.poppins(
                    color: customColors.bodyTextColor,
                    fontSize: 15.5,
                  ),
                  decoration: themedInputDecoration(
                    labelText: "Username",
                    prefixIcon: Icons.account_circle_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: GoogleFonts.poppins(
                    color: customColors.bodyTextColor,
                    fontSize: 15.5,
                  ),
                  decoration: themedInputDecoration(
                    labelText: "Email",
                    prefixIcon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  style: GoogleFonts.poppins(
                    color: customColors.bodyTextColor,
                    fontSize: 15.5,
                  ),
                  obscureText: !_passwordVisible,
                  decoration: themedInputDecoration(
                    labelText: "Password",
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: customColors.secondaryTextColor?.withOpacity(
                          0.7,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32), // Spasi lebih besar sebelum tombol
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    )
                    : ElevatedButton.icon(
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 22,
                      ),
                      label: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sudah punya akun?",
                      style: GoogleFonts.poppins(
                        color: customColors.secondaryTextColor,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
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
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
