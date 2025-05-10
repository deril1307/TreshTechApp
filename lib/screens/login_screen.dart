import 'package:flutter/material.dart';
import 'package:tubes_mobile/screens/register_screen.dart';
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

  Future<void> loginUser() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email atau Username belum diisi")),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Password belum diisi")));
      return;
    }

    setState(() => isLoading = true);

    final response = await ApiService.login(identifier, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response["message"] == "Login berhasil!") {
      await SharedPrefs.saveUserId(response["user_id"].toString());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/TrashTech.png', width: 150, height: 150),
              SizedBox(height: 20),
              Text(
                "TrashTech Login",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: identifierController,
                decoration: InputDecoration(
                  labelText: "Email atau Username",
                  prefixIcon: Icon(Icons.person, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 50,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    ),
                child: Text(
                  "Belum punya akun? Register",
                  style: TextStyle(color: Colors.green[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
