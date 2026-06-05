import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/song_importer.dart';
import '../domain/song.dart';

class SongsPage extends StatefulWidget {
  const SongsPage({super.key});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  final scanner = SongImporter();

  List<Track> tracks = [];

  String? folderName;

  Future<void> selectFolder() async {
    final folderPath =
        await FilePicker.getDirectoryPath();

    if (folderPath == null) return;

    final result = await scanner.scanFolder(folderPath);

    setState(() {
      tracks = result;
      folderName = folderPath.split('/').last;
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

            Expanded(
              child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];

                  return ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(track.name),
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