import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqScreen extends StatelessWidget {
  final List<Map<String, String>> faqData;
  final Color appBarColor;
  final Color primaryAccentColor;
  final Color scaffoldBgColor;
  final Color cardColor;
  final Color titleTextColor;
  final Color bodyTextColor;
  final Color secondaryTextColor;

  const FaqScreen({
    super.key,
    required this.faqData,
    required this.appBarColor,
    required this.primaryAccentColor,
    required this.scaffoldBgColor,
    required this.cardColor,
    required this.titleTextColor,
    required this.bodyTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          "Pertanyaan Umum (FAQ)",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1.0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqData.length,
        itemBuilder: (context, index) {
          final faqItem = faqData[index];
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: cardColor,
            child: ExpansionTile(
              iconColor: primaryAccentColor,
              collapsedIconColor: secondaryTextColor,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              title: Text(
                faqItem['question']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: titleTextColor,
                  fontSize: 16,
                ),
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                    top: 4.0,
                  ),
                  child: Text(
                    faqItem['answer']!,
                    style: GoogleFonts.poppins(
                      color: bodyTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 0),
      ),
    );
  }
}
