// ignore_for_file: await_only_futures, unused_import, duplicate_import

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/screens/register_screen.dart';
import 'package:tubes_mobile/screens/requestreset_screen.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/screens/home_screen.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import '../main.dart';

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
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;
    final theme = Theme.of(context); // Ambil theme untuk snackbar

    if (identifier.isEmpty) {
      _showSnackBar("Email atau Username belum diisi", theme.colorScheme.error);
      return;
    }

    if (password.isEmpty) {
      _showSnackBar("Password belum diisi", theme.colorScheme.error);
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    final response = await ApiService.login(identifier, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response["message"] == "Login berhasil!") {
      await SharedPrefs.saveUserId(response["user_id"].toString());
      // Simpan juga data lain jika ada, misal username, profile picture dari response login
      // await SharedPrefs.saveUsername(response["username"]); // Contoh
      // await SharedPrefs.saveProfilePicture(response["profile_picture_url"]); // Contoh

      if (!mounted) return;
      _showSuccessDialog("Login berhasil!");

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog sukses
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showSnackBar(
        response["message"] ?? "Terjadi kesalahan saat login.",
        theme.colorScheme.error,
      );
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: theme.colorScheme.onError),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: theme.primaryColor, // Warna ikon sukses dari tema
              size: 52,
            ),
            title: Text(
              "Sukses",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: customColors.titleTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: customColors.bodyTextColor,
              ),
              textAlign: TextAlign.center,
            ),
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
        hintText: "Masukkan $labelText",
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
        ), // Fill color disesuaikan
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/TrashTech.png', // Pastikan path aset benar
                  width: 120, // Ukuran disesuaikan
                  height: 120,
                  // Pertimbangkan untuk menyediakan versi aset yang berbeda untuk dark mode jika perlu
                  // color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : null, // Contoh jika ikon perlu di-invert
                ),
                const SizedBox(height: 24),
                Text(
                  "Selamat Datang!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28, // Ukuran font lebih besar
                    fontWeight: FontWeight.bold,
                    color: customColors.titleTextColor, // Warna teks dari tema
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Login untuk melanjutkan ke TrashTech",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16, // Ukuran font disesuaikan
                    color:
                        customColors.secondaryTextColor, // Warna teks dari tema
                  ),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: identifierController,
                  style: GoogleFonts.poppins(
                    color: customColors.bodyTextColor,
                    fontSize: 15.5,
                  ), // Warna teks input
                  keyboardType: TextInputType.emailAddress,
                  decoration: themedInputDecoration(
                    labelText: "Email atau Username",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: passwordController,
                  style: GoogleFonts.poppins(
                    color: customColors.bodyTextColor,
                    fontSize: 15.5,
                  ), // Warna teks input
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
                        ), // Warna ikon mata
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
                          ),
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
                        color: theme.primaryColor, // Warna link dari tema
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor, // Warna loading dari tema
                      ),
                    )
                    : ElevatedButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 22),
                      onPressed: loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.primaryColor, // Warna tombol dari tema
                        foregroundColor:
                            theme
                                .colorScheme
                                .onPrimary, // Warna teks/ikon pada tombol
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        minimumSize: const Size(
                          double.infinity,
                          52,
                        ), // Tombol full-width
                      ),
                      label: Text(
                        "Login",
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun?",
                      style: GoogleFonts.poppins(
                        color: customColors.secondaryTextColor,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const RegisterScreen(), // Pastikan RegisterScreen juga theme-aware
                            ),
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
                          color: theme.primaryColor, // Warna link dari tema
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
