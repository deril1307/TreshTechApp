import 'package:flutter/material.dart';
import 'package:tubes_mobile/screens/home_screen.dart';
import 'package:tubes_mobile/screens/login_screen.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Pastikan Flutter sudah siap
  await SharedPrefs.init(); // Inisialisasi SharedPreferences
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<String?>(
        future: Future.value(SharedPrefs.getUserId()), // Ambil User ID
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ); // Tampilkan loading
          } else {
            return snapshot.data == null
                ? LoginScreen()
                : HomeScreen(); // Redirect ke Login atau Home
          }
        },
      ),
    );
  }
}
