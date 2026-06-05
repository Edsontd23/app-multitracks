import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/song.dart';
import '../domain/song_asset_type.dart';

class SongDetailPage extends StatelessWidget {
  final Song song;

  const SongDetailPage({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
      ),
      body:
       ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (song.artwork != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Image.file(
              File(song.artwork!.path),
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
          _section(
            '🎵 Audio',
            song.byType(SongAssetType.audio),
          ),
          _section(
            '🎹 MIDI',
            song.byType(SongAssetType.midi),
          ),
          _section(
            '📖 Lyrics',
            song.byType(SongAssetType.lyrics),
          ),
          _section(
            '🎼 Chords',
            song.byType(SongAssetType.chords),
          ),
          _section(
            '🖼 Artwork',
            song.byType(SongAssetType.artwork),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List assets,
  ) {
    if (assets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: ExpansionTile(
        title: Text(title),
        children: assets
            .map(
              (asset) => ListTile(
                title: Text(asset.name),
              ),
            )
            .toList(),
      ),
    );
  }
}