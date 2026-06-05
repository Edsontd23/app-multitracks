import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerPage extends StatelessWidget {
  final String filePath;

  const PdfViewerPage({
    super.key,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: PdfView(
        controller: PdfController(
          document: PdfDocument.openFile(
            filePath,
          ),
        ),
      ),
    );
  }
}