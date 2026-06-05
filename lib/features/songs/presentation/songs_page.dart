import 'package:app_multitracks/features/songs/data/song_library_importer.dart';
import 'package:app_multitracks/features/songs/presentation/song_detail_page.dart';
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
  final SongLibraryImporter libraryImporter = SongLibraryImporter();

  List<Song> songs = [];

  String? folderName;

  Future<void> selectFolder() async {
    final folderPath =
        await FilePicker.getDirectoryPath();

    if (folderPath == null) return;

    final result =
        await libraryImporter.importLibrary(
          folderPath,
        );

    setState(() {
      songs = result;
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

            if (songs.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];

                  return ListTile(
                    leading: const Icon(Icons.library_music),
                    title: Text(song.title),
                    subtitle: Text(
                      '${song.assets.length} archivos',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongDetailPage(song: song),
                        ),
                      );
                    },
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