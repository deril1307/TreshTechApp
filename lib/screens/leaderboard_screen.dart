import 'package:flutter/material.dart';
import '../services/api_service.dart'; // sesuaikan path ini

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      final data = await ApiService.getLeaderboard();
      setState(() {
        leaderboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 7, 168, 13),
        title: const Text(
          "Leaderboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text("Error: $error"))
              : leaderboardData.length < 3
              ? Center(child: Text("Data leaderboard kurang dari 3 pengguna."))
              : Column(
                children: [
                  SizedBox(height: 16),
                  Text(
                    "Ends in 2d 23Hours",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTopUser(context, leaderboardData[1], 2),
                      _buildTopUser(context, leaderboardData[0], 1),
                      _buildTopUser(context, leaderboardData[2], 3),
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: leaderboardData.length - 3,
                        itemBuilder: (context, index) {
                          final user = leaderboardData[index + 3];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                _getAvatarUrl(user['username']),
                              ),
                            ),
                            title: Text(user["username"]),
                            subtitle: Text("Poin: ${user["points"]}"),
                            trailing: Text("${index + 4}"),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTopUser(
    BuildContext context,
    Map<String, dynamic> user,
    int rank,
  ) {
    double height = rank == 1 ? 140 : 100;
    return Column(
      children: [
        Container(
          height: height,
          width: 90,
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 7, 168, 13),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(_getAvatarUrl(user["username"])),
                radius: 25,
              ),
              SizedBox(height: 5),
              Text(
                user["username"],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "${user["points"]} Poin",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        SizedBox(height: 5),
        Text(
          "$rank",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Fungsi untuk buat avatar unik berdasarkan nama user
  String _getAvatarUrl(String name) {
    final seed = name.hashCode % 100;
    return "https://randomuser.me/api/portraits/men/${seed}.jpg";
  }
}
