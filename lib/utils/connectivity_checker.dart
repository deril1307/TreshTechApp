import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker extends StatefulWidget {
  const ConnectivityChecker({super.key});

  @override
  _ConnectivityCheckerState createState() => _ConnectivityCheckerState();
}

class _ConnectivityCheckerState extends State<ConnectivityChecker> {
  bool _isDialogShown = false; // Prevent the dialog from showing repeatedly

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((connectivityResult) {
      _handleConnectivityChange(connectivityResult as ConnectivityResult);
    });
  }

  // Check the initial connectivity status
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _handleConnectivityChange(connectivityResult as ConnectivityResult);
  }

  // Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    if (result == ConnectivityResult.none && !_isDialogShown) {
      _isDialogShown = true; // Set flag to true when dialog is shown
      _showNoConnectionDialog();
    } else if (result != ConnectivityResult.none) {
      _isDialogShown = false; // Reset flag if internet is available
    }
  }

  // Show dialog when there is no internet connection
  void _showNoConnectionDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible:
            false, // Dialog is not dismissible until the user presses OK
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text("Jaringan Buruk"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Maaf, jaringan Anda sedang buruk.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Image.asset(
                    "assets/no_connection.png",
                    height: 100,
                  ), // Make sure the image exists
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("OK"),
                ),
              ],
            ),
      ).then((_) {
        _isDialogShown = false; // Reset flag after the dialog is dismissed
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink(); // This widget does not display anything on screen
  }
}
