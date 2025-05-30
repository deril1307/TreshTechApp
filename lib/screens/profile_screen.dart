// ignore_for_file: unused_import, unnecessary_null_comparison, unnecessary_cast, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/services/api_service.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';
import 'package:tubes_mobile/screens/login_screen.dart';
import 'package:tubes_mobile/screens/edit_profile_screen.dart';
import 'package:tubes_mobile/screens/faq_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import MyApp dan CustomThemeColors dari main.dart
// Sesuaikan path '../main.dart' jika struktur folder Anda berbeda
import '../main.dart'; // Asumsi main.dart ada di direktori parent

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  String? phoneNumber;
  String? address;
  double saldo = 0;
  int poin = 0;
  String? profilePicture;
  bool isLoading = true;

  // HAPUS SEMUA DEFINISI WARNA HARDCODE DI SINI
  // final Color appBarColor = const Color.fromARGB(255, 38, 198, 38);
  // final Color primaryAccentColor = const Color.fromARGB(255, 27, 154, 27);
  // ... dan seterusnya

  final List<Map<String, String>> _faqData = [
    {
      'question': 'Bagaimana cara mengubah profil saya?',
      'answer':
          'Anda dapat mengubah informasi profil Anda seperti nama, nomor telepon, dan alamat dengan menekan tombol "Edit Profil" yang ada di bagian atas halaman profil ini.',
    },
    {
      'question': 'Di mana saya bisa melihat jumlah poin dan saldo saya?',
      'answer':
          'Jumlah poin dan saldo Anda ditampilkan dengan jelas dalam kartu "Poin Anda" dan "Saldo Anda" di halaman profil. Informasi ini akan diperbarui secara otomatis.',
    },
    {
      'question': 'Apakah data saya aman?',
      'answer':
          'Kami menjaga privasi dan keamanan data Anda dengan serius. Informasi pribadi Anda disimpan dengan aman dan hanya digunakan untuk keperluan layanan aplikasi ini.',
    },
    {
      'question': 'Bagaimana cara melakukan logout?',
      'answer':
          'Untuk keluar dari akun Anda, tekan tombol "Logout Akun" di bagian bawah halaman profil. Anda akan diminta konfirmasi sebelum proses logout dilakukan.',
    },
    {
      'question': 'Apa yang terjadi jika saya tidak memiliki koneksi internet?',
      'answer':
          'Jika tidak ada koneksi internet, aplikasi akan mencoba menampilkan data profil yang terakhir disimpan secara lokal. Namun, untuk pembaruan data terkini atau melakukan transaksi, koneksi internet diperlukan.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    // Set isLoading true hanya jika data pengguna belum ada
    if (username == null) {
      setState(() => isLoading = true);
    }

    String? userId = await SharedPrefs.getUserId();

    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    var savedProfile = await SharedPrefs.getUserProfile();
    var savedBalance = await SharedPrefs.getUserBalance();
    var savedPoints = await SharedPrefs.getUserPoints();
    bool localDataAvailable =
        savedProfile != null && savedBalance != null && savedPoints != null;

    if (localDataAvailable) {
      if (mounted) {
        setState(() {
          username = savedProfile["full_name"] ?? "Pengguna Baru";
          phoneNumber = savedProfile["phone_number"] ?? "Belum diinput";
          address = savedProfile["address"] ?? "Belum diinput";
          profilePicture = savedProfile["profile_picture"];
          saldo = double.tryParse(savedBalance.toString()) ?? 0.00;
          poin = int.tryParse(savedPoints.toString()) ?? 0;
          // Jika data lokal ada, kita bisa set isLoading false di sini
          // kecuali jika kita selalu ingin fetch dari API jika ada koneksi.
          // Untuk saat ini, biarkan isLoading dihandle setelah pengecekan koneksi.
        });
      }
    }

    var connectivityResultList = await (Connectivity().checkConnectivity());
    // Pengecekan konektivitas yang lebih sederhana dan aman
    bool isOnline = !connectivityResultList.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        var results = await Future.wait([
          ApiService.getUserData(userId),
          ApiService.fetchUserProfile(userId),
        ]);

        var userData = results[0];
        var userProfile = results[1];

        await SharedPrefs.saveUserProfile(userProfile as Map<String, dynamic>);
        await SharedPrefs.saveUserBalance(userData["balance"]?.toString());
        await SharedPrefs.saveUserPoints(userData["points"]?.toString());

        if (mounted) {
          setState(() {
            username =
                (userProfile["full_name"]?.isEmpty ?? true)
                    ? "Pengguna Baru"
                    : userProfile["full_name"];
            phoneNumber =
                (userProfile["phone_number"]?.isEmpty ?? true)
                    ? "Belum diinput"
                    : userProfile["phone_number"];
            address =
                (userProfile["address"]?.isEmpty ?? true)
                    ? "Belum diinput"
                    : userProfile["address"];
            profilePicture =
                (userProfile["profile_picture"]?.isEmpty ?? true)
                    ? null
                    : userProfile["profile_picture"];
            saldo =
                double.tryParse(userData["balance"]?.toString() ?? "0.00") ??
                0.00;
            poin = int.tryParse(userData["points"]?.toString() ?? "0") ?? 0;
            isLoading = false; // Data dari API berhasil dimuat
          });
        }
      } catch (e) {
        print(
          "Gagal memuat data user dari API, menggunakan data lokal jika ada: $e",
        );
        if (mounted)
          setState(() => isLoading = false); // Gagal API, berhenti loading
      }
    } else {
      // Jika offline, dan data lokal sudah dimuat, set isLoading false
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _confirmLogout(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.cardColor,
            title: Text(
              "Konfirmasi Logout",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: customColors.titleTextColor,
              ),
            ),
            content: Text(
              "Apakah Anda yakin ingin keluar dari akun ini?",
              style: GoogleFonts.poppins(
                color: customColors.secondaryTextColor,
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "Batal",
                  style: GoogleFonts.poppins(
                    color: customColors.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red.shade700, // Warna spesifik untuk logout
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await SharedPrefs.clearUserData();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                child: Text(
                  "Logout",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final customColors = theme.extension<CustomThemeColors>()!;
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Profil Saya",
          // Style diambil dari AppBarTheme di main.dart
        ),
        // backgroundColor dan iconTheme juga dari AppBarTheme
        elevation: 1.0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: theme.primaryColor,
        child:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                )
                : username == null &&
                    !isLoading // Jika userId tidak ada setelah loading
                ? _buildLoginPrompt(context)
                : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileHeaderCard(context),
                      const SizedBox(height: 20),
                      _buildStatsRow(context),
                      const SizedBox(height: 20),
                      _buildInfoDetailsCard(context),
                      const SizedBox(height: 20),
                      _buildThemeToggleItem(
                        context,
                        isDarkMode,
                      ), // Tombol Ganti Tema
                      const SizedBox(height: 12),
                      _buildFaqNavigationItem(context),
                      const SizedBox(height: 24),
                      _buildActionButton(
                        context: context,
                        label: "Logout Akun",
                        color:
                            Colors.red.shade600, // Warna spesifik untuk logout
                        onPressed: () => _confirmLogout(context),
                        icon: Icons.logout_rounded,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 80,
              color: theme.hintColor.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              "Anda Belum Login",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: customColors.titleTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan login untuk melihat dan mengelola profil Anda.",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: customColors.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              context: context,
              label: "Login Sekarang",
              color: theme.primaryColor,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: Icons.login_rounded,
              isFullWidth: false, // Tombol tidak full width
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfilePicture(context),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  username ?? "Pengguna",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: customColors.titleTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  context: context,
                  label: "Edit Profil",
                  color: theme.primaryColor, // Gunakan warna primer dari tema
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(),
                      ),
                    );
                    if (result == true && mounted) {
                      _loadUserData();
                    }
                  },
                  isSmall: true,
                  icon: Icons.edit_note_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final theme = Theme.of(context);
    // customColors tidak digunakan di sini
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            "Poin Anda",
            "$poin Poin",
            Icons.star_border_purple500_rounded,
            Colors.amber.shade700, // Warna ikon poin bisa tetap spesifik
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            context,
            "Saldo Anda",
            "Rp ${saldo.toStringAsFixed(0)}",
            Icons.account_balance_wallet_outlined,
            theme.primaryColor, // Gunakan warna primer dari tema
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor, // Warna ikon spesifik
  ) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    bool isPlaceholder =
        (title.contains("Poin") &&
            poin == 0 &&
            (username != "Pengguna Baru" && username != null)) ||
        (title.contains("Saldo") &&
            saldo == 0.00 &&
            (username != "Pengguna Baru" && username != null));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: customColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  isPlaceholder
                      ? theme.hintColor.withOpacity(0.8)
                      : customColors.titleTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    // customColors tidak digunakan di sini
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            "Nomor Telepon",
            phoneNumber ?? "Belum diinput",
            Icons.phone_iphone_rounded,
            theme.primaryColor, // Gunakan warna primer dari tema
          ),
          Divider(
            color: theme.dividerColor,
            height: 20,
            thickness: 0.8,
            indent: 16,
            endIndent: 16,
          ),
          _buildInfoRow(
            context,
            "Alamat Lengkap",
            address ?? "Belum diinput",
            Icons.location_city_rounded,
            theme.primaryColor, // Gunakan warna primer dari tema
          ),
        ],
      ),
    );
  }

  // Item baru untuk mengganti tema
  Widget _buildThemeToggleItem(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero, // Hapus margin default Card jika menempel
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0, // Padding vertikal bisa disesuaikan
        ),
        leading: Icon(
          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: theme.primaryColor,
          size: 28,
        ),
        title: Text(
          "Mode Tampilan",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: customColors.titleTextColor,
            fontSize: 16,
          ),
        ),
        trailing: Switch(
          value: isDarkMode,
          onChanged: (value) {
            MyApp.of(
              context,
            )?.changeTheme(value ? ThemeMode.dark : ThemeMode.light);
          },
          activeColor: theme.primaryColor,
          inactiveThumbColor:
              theme.brightness == Brightness.light
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
          inactiveTrackColor:
              theme.brightness == Brightness.light
                  ? Colors.grey.shade200
                  : Colors.grey.shade800.withOpacity(0.5),
        ),
        onTap: () {
          // Memungkinkan tap pada seluruh list tile untuk toggle switch
          MyApp.of(
            context,
          )?.changeTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
        },
      ),
    );
  }

  Widget _buildFaqNavigationItem(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;

    // Ambil warna dari tema saat ini untuk dikirim ke FaqScreen
    // Ini PENTING jika FaqScreen belum sepenuhnya theme-aware
    final Color currentAppBarColor =
        theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final Color currentPrimaryAccentColor =
        theme.primaryColor; // primaryAccentColor diganti primaryColor
    final Color currentScaffoldBgColor = theme.scaffoldBackgroundColor;
    final Color currentCardColor = theme.cardColor;
    final Color? currentTitleTextColor = customColors.titleTextColor;
    final Color? currentBodyTextColor = customColors.bodyTextColor;
    final Color? currentSecondaryTextColor = customColors.secondaryTextColor;

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Icon(
          Icons.help_outline_rounded,
          color: theme.primaryColor, // Gunakan warna primer dari tema
          size: 28,
        ),
        title: Text(
          "Pertanyaan Umum (FAQ)",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: customColors.titleTextColor,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: customColors.secondaryTextColor,
          size: 28,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (newContext) => FaqScreen(
                    // Gunakan newContext dari builder
                    faqData: _faqData,
                    // Idealnya, FaqScreen juga mengambil warna dari Theme.of(newContext)
                    // Jika belum, Anda bisa mengirim warna seperti ini:
                    appBarColor: currentAppBarColor,
                    primaryAccentColor: currentPrimaryAccentColor,
                    scaffoldBgColor: currentScaffoldBgColor,
                    cardColor: currentCardColor,
                    titleTextColor:
                        currentTitleTextColor ??
                        AppThemes.lightTheme
                            .extension<CustomThemeColors>()!
                            .titleTextColor!, // Fallback
                    bodyTextColor:
                        currentBodyTextColor ??
                        AppThemes.lightTheme
                            .extension<CustomThemeColors>()!
                            .bodyTextColor!, // Fallback
                    secondaryTextColor:
                        currentSecondaryTextColor ??
                        AppThemes.lightTheme
                            .extension<CustomThemeColors>()!
                            .secondaryTextColor!, // Fallback
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required Color
    color, // Warna background tombol, bisa spesifik (merah untuk logout)
    required VoidCallback onPressed,
    bool isSmall = false,
    IconData? icon,
    bool isFullWidth = false,
  }) {
    // final theme = Theme.of(context); // Tidak selalu dibutuhkan jika warna tombol spesifik

    return SizedBox(
      height: isSmall ? 40 : 50,
      width: isFullWidth ? double.infinity : (isSmall ? null : double.infinity),
      child: ElevatedButton.icon(
        icon:
            icon != null
                ? Icon(
                  icon,
                  size: isSmall ? 18 : 20,
                ) // Warna ikon diambil dari foregroundColor
                : const SizedBox.shrink(),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            // Warna teks diambil dari foregroundColor
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // Warna background tombol
          foregroundColor:
              Colors.white, // Warna teks dan ikon pada tombol ini selalu putih
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 20,
            vertical: isSmall ? 8 : 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 52,
        backgroundColor: theme.primaryColor.withOpacity(0.15),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: theme.dividerColor.withOpacity(
            0.5,
          ), // Background placeholder
          backgroundImage:
              (profilePicture != null && profilePicture!.isNotEmpty)
                  ? CachedNetworkImageProvider(profilePicture!)
                  : null,
          child:
              (profilePicture == null || profilePicture!.isEmpty)
                  ? Icon(
                    Icons.person_outline_rounded,
                    size: 50,
                    color: theme.hintColor.withOpacity(
                      0.8,
                    ), // Warna ikon placeholder
                  )
                  : null,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor, // Warna untuk background ikon dan ikon itu sendiri
  ) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomThemeColors>()!;
    bool isPlaceholderValue = (value == "Belum diinput" || value == "-");

    return Material(
      color: Colors.transparent, // Agar InkWell tidak menutupi warna Card
      child: InkWell(
        onTap: () {
          // Aksi bisa ditambahkan di sini
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), // Background untuk ikon
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20), // Ikon
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: customColors.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            isPlaceholderValue
                                ? FontWeight.normal
                                : FontWeight.w600,
                        color:
                            isPlaceholderValue
                                ? theme
                                    .hintColor // Warna untuk placeholder
                                : customColors.titleTextColor,
                        fontStyle:
                            isPlaceholderValue
                                ? FontStyle.italic
                                : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
