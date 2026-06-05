import 'dart:io';

import 'package:flutter/material.dart';

class TextViewerPage extends StatefulWidget {
  final String filePath;

  const TextViewerPage({
    super.key,
    required this.filePath,
  });

  @override
  State<TextViewerPage> createState() =>
      _TextViewerPageState();
}

class _TextViewerPageState
    extends State<TextViewerPage> {
  String content = '';

  @override
  void initState() {
    super.initState();
    loadFile();
  }

  Future<void> loadFile() async {
    final text =
        await File(widget.filePath).readAsString();

    setState(() {
      content = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(content),
      ),
    );
  }
}