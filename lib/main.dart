import 'package:flutter/material.dart';
import 'package:tubes_mobile/screens/home_screen.dart';
import 'package:tubes_mobile/screens/login_screen.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<String?>(
        future: Future.value(SharedPrefs.getUserId()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            return snapshot.data == null
                ? LoginScreen()
                : HomeScreen(key: HomeScreen.homeScreenKey); // Pass the key
          }
        },
      ),
    );
  }
}
