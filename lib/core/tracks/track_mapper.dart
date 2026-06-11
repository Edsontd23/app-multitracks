import 'package:flutter/material.dart';
import 'track_style.dart';

class TrackMapper {

  static TrackStyle fromName(String name) {

    final track = name.toLowerCase();

    // FX

    if (track.contains('fx') ||
        track.contains('effect')) {

      return const TrackStyle(
        icon: Icons.blur_on,
        color: Colors.deepOrange,
        category: 'FX',
      );
    }

    // CLICK

    if (track.contains('click')) {

      return const TrackStyle(
        icon: Icons.timer,
        color: Colors.yellow,
        category: 'CLICK',
      );
    }

    // KICK

    if (track.contains('kick')) {

      return const TrackStyle(
        icon: Icons.album,
        color: Colors.redAccent,
        category: 'KICK',
      );
    }

    // SNARE

    if (track.contains('snare')) {

      return const TrackStyle(
        icon: Icons.music_note,
        color: Colors.orange,
        category: 'SNARE',
      );
    }

    // DRUMS

    if (track.contains('drum')) {

      return const TrackStyle(
        icon: Icons.album,
        color: Colors.red,
        category: 'DRUMS',
      );
    }

    // BASS

    if (track.contains('bass')) {

      return const TrackStyle(
        icon: Icons.graphic_eq,
        color: Colors.teal,
        category: 'BASS',
      );
    }

    // VOCALS

    if (track.contains('vocal')) {

      return const TrackStyle(
        icon: Icons.mic,
        color: Colors.blue,
        category: 'VOCALS',
      );
    }

    // PIANO

    if (track.contains('piano')) {

      return const TrackStyle(
        icon: Icons.piano,
        color: Colors.purple,
        category: 'PIANO',
      );
    }

    // KEYS

    if (track.contains('keys')) {

      return const TrackStyle(
        icon: Icons.piano,
        color: Colors.deepPurple,
        category: 'KEYS',
      );
    }

    return const TrackStyle(
      icon: Icons.audiotrack,
      color: Colors.grey,
      category: 'AUDIO',
    );
  }
}