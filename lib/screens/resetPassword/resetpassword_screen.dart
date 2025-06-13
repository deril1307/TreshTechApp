import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../loginAndRegist/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({required this.email, super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final tokenController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  int countdown = 120;

  void startTimer() {
    countdown = 120;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => countdown--);
      return countdown > 0;
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    tokenController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final token = tokenController.text.trim();
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (token.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      showMessage("Semua field wajib diisi");
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage("Password dan konfirmasi tidak cocok");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.resetPassword(
        widget.email,
        token,
        newPassword,
      );

      if (mounted) {
        setState(() => isLoading = false);
        showMessage(response["message"]);

        if (response["success"] == true) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showMessage("Terjadi kesalahan saat reset password");
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget buildInputField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildInputField("Masukkan Token", tokenController),
              buildInputField(
                "Password Baru",
                passwordController,
                isPassword: true,
              ),
              buildInputField(
                "Konfirmasi Password",
                confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: resetPassword,
                    child: const Text("Reset Password"),
                  ),
              const SizedBox(height: 10),
              TextButton(
                onPressed:
                    countdown == 0
                        ? () async {
                          setState(() => countdown = 120);
                          startTimer();
                          await ApiService.requestResetCode(widget.email);
                          showMessage("Kode reset telah dikirim ulang");
                        }
                        : null,
                child: Text("Kirim ulang kode (${countdown}s)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
