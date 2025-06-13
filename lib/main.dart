// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tubes_mobile/screens/home_screen.dart';
import 'package:tubes_mobile/screens/loginAndRegist/login_screen.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';

// Tema Aplikasi
class AppThemes {
  // Warna untuk Light Theme
  static final Color _lightPrimaryColor = const Color.fromARGB(255, 7, 168, 13);
  static final Color _lightPrimaryLightColor = const Color.fromARGB(
    255,
    66,
    199,
    73,
  );
  static final Color _lightPrimaryDarkColor = const Color.fromARGB(
    255,
    4,
    105,
    9,
  );
  static final Color _lightScaffoldBgColor = const Color(0xFFF0F4F8);
  static final Color _lightCardColor = Colors.white;
  static final Color _lightTitleTextColor = Colors.green.shade900; // Teks gelap
  static final Color _lightBodyTextColor = Colors.black.withOpacity(
    0.75,
  ); // Teks gelap
  static final Color _lightSecondaryTextColor =
      Colors.grey.shade600; // Teks abu-abu gelap
  static final Color _lightCardShadowColor = Colors.black.withOpacity(0.06);
  static final Color _lightDividerColor = Colors.grey.shade200;

  // Warna untuk Dark Theme
  static final Color _darkPrimaryColor = const Color.fromARGB(
    255,
    10,
    140,
    15,
  ); // Warna primer sedikit lebih terang
  static final Color _darkPrimaryLightColor = const Color.fromARGB(
    255,
    50,
    160,
    55,
  );
  static final Color _darkPrimaryDarkColor = const Color.fromARGB(
    255,
    2,
    75,
    5,
  );
  static final Color _darkScaffoldBgColor = const Color(
    0xFF121212,
  ); // Background UI gelap
  static final Color _darkCardColor = const Color(
    0xFF1E1E1E,
  ); // Warna kartu UI gelap
  static final Color _darkTitleTextColor = Colors.green.shade300; // Teks terang
  static final Color _darkBodyTextColor = Colors.white.withOpacity(
    0.87,
  ); // Teks terang
  static final Color _darkSecondaryTextColor = Colors.grey.shade400;
  static final Color _darkCardShadowColor = Colors.black.withOpacity(0.2);
  static final Color _darkDividerColor = Colors.grey.shade700;

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _lightPrimaryColor,
    primaryColorLight: _lightPrimaryLightColor,
    primaryColorDark: _lightPrimaryDarkColor,
    scaffoldBackgroundColor: _lightScaffoldBgColor,
    cardColor: _lightCardColor,
    dividerColor: _lightDividerColor,
    hintColor: _lightSecondaryTextColor,
    shadowColor: _lightCardShadowColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightPrimaryColor,
      elevation: 2.0,
      iconTheme: const IconThemeData(color: Colors.white), // Ikon AppBar putih
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.white, // Judul AppBar putih
      ),
    ),
    textTheme: TextTheme(
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _lightTitleTextColor,
      ), // Teks gelap
      bodyLarge: GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: _lightBodyTextColor,
      ), // Teks gelap
      bodyMedium: GoogleFonts.poppins(
        fontSize: 12,
        color: _lightSecondaryTextColor,
      ), // Teks gelap
      labelLarge: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _lightTitleTextColor.withOpacity(0.9), // Teks gelap
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      CustomThemeColors(
        titleTextColor: _lightTitleTextColor,
        bodyTextColor: _lightBodyTextColor,
        secondaryTextColor: _lightSecondaryTextColor,
        balanceCardGradient: [_lightPrimaryDarkColor, _lightPrimaryColor],
        headerSectionBackground: _lightPrimaryLightColor,
      ),
    ],
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkPrimaryColor,
    primaryColorLight: _darkPrimaryLightColor,
    primaryColorDark: _darkPrimaryDarkColor,
    scaffoldBackgroundColor: _darkScaffoldBgColor, // UI gelap
    cardColor: _darkCardColor, // UI gelap
    dividerColor: _darkDividerColor,
    hintColor: _darkSecondaryTextColor,
    shadowColor: _darkCardShadowColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkPrimaryDarkColor, // AppBar UI gelap
      elevation: 2.0,
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ), // Ikon AppBar terang
      titleTextStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.white, // Judul AppBar terang
      ),
    ),
    textTheme: TextTheme(
      // Konfigurasi teks untuk mode gelap agar kontras (terang)
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _darkTitleTextColor,
      ), // Teks terang
      bodyLarge: GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: _darkBodyTextColor,
      ), // Teks terang
      bodyMedium: GoogleFonts.poppins(
        fontSize: 12,
        color: _darkSecondaryTextColor,
      ), // Teks terang
      labelLarge: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _darkTitleTextColor.withOpacity(0.9), // Teks terang
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      CustomThemeColors(
        // Warna teks kustom juga terang untuk mode gelap
        titleTextColor: _darkTitleTextColor,
        bodyTextColor: _darkBodyTextColor,
        secondaryTextColor: _darkSecondaryTextColor,
        balanceCardGradient: [_darkPrimaryDarkColor, _darkPrimaryColor],
        headerSectionBackground: _darkPrimaryLightColor.withOpacity(0.5),
      ),
    ],
  );
}

// Custom Theme Extension untuk warna spesifik
@immutable
class CustomThemeColors extends ThemeExtension<CustomThemeColors> {
  const CustomThemeColors({
    required this.titleTextColor,
    required this.bodyTextColor,
    required this.secondaryTextColor,
    required this.balanceCardGradient,
    required this.headerSectionBackground,
  });

  final Color? titleTextColor;
  final Color? bodyTextColor;
  final Color? secondaryTextColor;
  final List<Color>? balanceCardGradient;
  final Color? headerSectionBackground;

  @override
  CustomThemeColors copyWith({
    Color? titleTextColor,
    Color? bodyTextColor,
    Color? secondaryTextColor,
    List<Color>? balanceCardGradient,
    Color? headerSectionBackground,
  }) {
    return CustomThemeColors(
      titleTextColor: titleTextColor ?? this.titleTextColor,
      bodyTextColor: bodyTextColor ?? this.bodyTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      balanceCardGradient: balanceCardGradient ?? this.balanceCardGradient,
      headerSectionBackground:
          headerSectionBackground ?? this.headerSectionBackground,
    );
  }

  @override
  CustomThemeColors lerp(ThemeExtension<CustomThemeColors>? other, double t) {
    if (other is! CustomThemeColors) {
      return this;
    }
    return CustomThemeColors(
      titleTextColor: Color.lerp(titleTextColor, other.titleTextColor, t),
      bodyTextColor: Color.lerp(bodyTextColor, other.bodyTextColor, t),
      secondaryTextColor: Color.lerp(
        secondaryTextColor,
        other.secondaryTextColor,
        t,
      ),
      balanceCardGradient: [
        Color.lerp(balanceCardGradient?[0], other.balanceCardGradient?[0], t)!,
        Color.lerp(balanceCardGradient?[1], other.balanceCardGradient?[1], t)!,
      ],
      headerSectionBackground: Color.lerp(
        headerSectionBackground,
        other.headerSectionBackground,
        t,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs.init(); // Inisialisasi SharedPrefs Anda
  runApp(MyApp()); // MyApp sekarang StatefulWidget
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // Default ke tema sistem
  static const String _themePrefKey =
      'theme_mode_preference'; // Kunci unik untuk SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themePrefKey);
    if (mounted) {
      setState(() {
        if (themeModeString == 'light') {
          _themeMode = ThemeMode.light;
        } else if (themeModeString == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode =
              ThemeMode
                  .system; // Atau ThemeMode.light jika tidak ingin default ke sistem
        }
      });
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    if (mode == ThemeMode.light) {
      themeModeString = 'light';
    } else if (mode == ThemeMode.dark) {
      themeModeString = 'dark';
    } else {
      themeModeString = 'system';
    }
    await prefs.setString(_themePrefKey, themeModeString);
  }

  void changeTheme(ThemeMode themeMode) {
    if (mounted) {
      setState(() {
        _themeMode = themeMode;
      });
    }
    _saveThemeMode(themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashTechBank', // Anda bisa menambahkan title
      theme: AppThemes.lightTheme, // Tema untuk mode terang
      darkTheme: AppThemes.darkTheme, // Tema untuk mode gelap
      themeMode: _themeMode, // Mode tema yang aktif
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<String?>(
        future: Future.value(
          SharedPrefs.getUserId(),
        ), // Asumsi getUserId sinkron
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  // Warna indikator akan diambil dari tema default MaterialApp sebelum tema spesifik dimuat
                ),
              ),
            );
          } else {
            if (snapshot.hasError) {
              // Handle error jika ada, misalnya kembali ke LoginScreen
              print("Error fetching userId: ${snapshot.error}");
              return LoginScreen();
            }
            // Jika userId null, tampilkan LoginScreen, jika tidak, tampilkan HomeScreen
            return snapshot.data == null
                ? LoginScreen()
                : HomeScreen(key: HomeScreen.homeScreenKey); // Pass the key
          }
        },
      ),
    );
  }
}
