import 'package:flutter/material.dart';

import '../../../core/session/session_instance.dart';

class MixerPage extends StatelessWidget {
  const MixerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final song = songSession.currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center(
          child: Text('No song selected'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mixer - ${song.title}'),
      ),
      body: const Center(
        child: Text('Mixer UI aquí'),
      ),
    );
  }
}