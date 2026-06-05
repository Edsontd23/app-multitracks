import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/song_importer.dart';
import '../domain/song.dart';

import 'package:flutter/foundation.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final SongImporter importer = SongImporter();

  Song? song;

  String? folderName;

  Future<void> selectFolder() async {
    debugPrint('Abriendo selector...');

    final folderPath = await FilePicker.getDirectoryPath();

    debugPrint('Carpeta seleccionada: $folderPath');

    if (folderPath == null) return;

    final result = await importer.importFolder(folderPath);

    debugPrint('Canción: ${result.title}');
    debugPrint('Assets encontrados: ${result.assets.length}');

    setState(() {
      song = result;
      folderName = result.title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FilledButton.icon(
              onPressed: selectFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Seleccionar carpeta'),
            ),

            const SizedBox(height: 24),

            if (folderName != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  folderName!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
              ),

            const SizedBox(height: 16),

            if (song != null)
            Expanded(
              child: ListView.builder(
                itemCount: song!.assets.length,
                itemBuilder: (context, index) {
                  final asset = song!.assets[index];

                  return ListTile(
                    title: Text(asset.name),
                    subtitle: Text(asset.type.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}