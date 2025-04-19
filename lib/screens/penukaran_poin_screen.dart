import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tubes_mobile/utils/shared_prefs.dart';

class PenukaranPoinScreen extends StatefulWidget {
  @override
  _PenukaranPoinScreenState createState() => _PenukaranPoinScreenState();
}

class _PenukaranPoinScreenState extends State<PenukaranPoinScreen> {
  int poin = 0;
  double saldo = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    int savedPoin = SharedPrefs.getPoin();
    double savedSaldo = SharedPrefs.getSaldo();
    setState(() {
      poin = savedPoin;
      saldo = savedSaldo;
    });
  }

  void _tukarPoin() async {
    if (poin < 10) {
      _showDialog("Gagal", "Minimal 10 poin untuk penukaran.");
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Tukar Poin"),
            content: Text("Tukar 10 poin menjadi Rp1.000?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Tukar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        poin -= 10;
        saldo += 1000;
      });

      await SharedPrefs.saveUserData(
        SharedPrefs.getUserId()!,
        (await SharedPrefs.getUsername()) ?? '',
        saldo,
        poin,
      );

      _showDialog("Berhasil", "Poin berhasil ditukar menjadi saldo.");
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Penukaran Poin", style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Poin Anda: $poin", style: GoogleFonts.poppins(fontSize: 20)),
            SizedBox(height: 10),
            Text(
              "Saldo Anda: Rp ${saldo.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.card_giftcard),
              label: Text("Tukar 10 Poin ke Rp1.000"),
              onPressed: _tukarPoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                textStyle: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
