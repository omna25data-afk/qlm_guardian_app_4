import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/screens/home_screen.dart'; // To use RegistryEntriesList

class RegistryEntriesScreen extends StatelessWidget {
  final int? bookNumber;
  final int? recordBookId;
  final int? contractTypeId;
  final String title;

  const RegistryEntriesScreen({
    super.key,
    this.bookNumber,
    this.recordBookId,
    this.contractTypeId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
      ),
      body: RegistryEntriesList(
        bookNumber: bookNumber,
        recordBookId: recordBookId,
        contractTypeId: contractTypeId,
      ),
    );
  }
}
