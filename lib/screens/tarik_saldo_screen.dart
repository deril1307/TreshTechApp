import 'package:flutter/material.dart';

class TarikSaldoScreen extends StatefulWidget {
  @override
  _TarikSaldoScreenState createState() => _TarikSaldoScreenState();
}

class _TarikSaldoScreenState extends State<TarikSaldoScreen> {
  final TextEditingController _jumlahController = TextEditingController();

  void _tarikSaldo() {
    final jumlah = _jumlahController.text;
    if (jumlah.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permintaan tarik saldo sebesar Rp $jumlah telah dikirim',
          ),
        ),
      );
      _jumlahController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tarik Saldo")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukkan jumlah saldo yang ingin ditarik:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah (Rp)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.send),
              label: Text("Tarik Saldo"),
              onPressed: _tarikSaldo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
