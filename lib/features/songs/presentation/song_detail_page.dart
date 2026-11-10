import 'dart:io';

import 'package:flutter/material.dart';

import '../data/audio_analysis_service.dart';
import '../domain/song.dart';
import '../domain/song_asset.dart';
import '../domain/song_asset_type.dart';
import '../domain/audio_analysis_result.dart';

import '../../../core/session/session_instance.dart';
import '../../player/presentation/player_page.dart';
import '../../mixer/presentation/mixer_page.dart';
import '../data/song_marker_storage.dart';

class SongDetailPage extends StatefulWidget {
  final Song song;

  const SongDetailPage({
    super.key,
    required this.song,
  });

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  final AudioAnalysisService _audioAnalyzer = AudioAnalysisService();

  late final TextEditingController _titleController;
  late final TextEditingController _bpmController;
  final SongMarkerStorage _songStorage = SongMarkerStorage();

  bool _analyzing = false;

  String? _timeSignature;
  String? _originalKey;

  AudioAnalysisResult? _analysisResult;

  static const List<String> _timeSignatures = [
    '4/4',
    '3/4',
    '6/8',
    '2/4',
    '5/4',
    '7/8',
    '12/8',
  ];

  static const List<String> _keys = [
    'C mayor',
    'C# mayor',
    'D mayor',
    'D# mayor',
    'E mayor',
    'F mayor',
    'F# mayor',
    'G mayor',
    'G# mayor',
    'A mayor',
    'A# mayor',
    'B mayor',
    'C menor',
    'C# menor',
    'D menor',
    'D# menor',
    'E menor',
    'F menor',
    'F# menor',
    'G menor',
    'G# menor',
    'A menor',
    'A# menor',
    'B menor',
  ];

  @override
  void initState() {
    super.initState();

    final song = widget.song;

    _titleController = TextEditingController(text: song.title);
    _bpmController = TextEditingController(
      text: song.bpm?.toString() ?? '',
    );

    _timeSignature = song.timeSignature;
    _originalKey = song.originalKey;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bpmController.dispose();
    super.dispose();
  }

  Future<void> _analyzeAudio() async {
    setState(() {
      _analyzing = true;
      _analysisResult = null;
    });

    try {
      final result = await _audioAnalyzer.analyzeSong(widget.song);

      if (!mounted) return;

      setState(() {
        _analysisResult = result;

        if (result.suggestedBpm != null) {
          _bpmController.text =
              result.suggestedBpm!.toStringAsFixed(1);
        }

        if (result.suggestedKey != null) {
          final suggestedKey =
              result.suggestedKey!.split(' (').first;

          if (_keys.contains(suggestedKey)) {
            _originalKey = suggestedKey;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al analizar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  Future<void> _saveConfiguration() async {
    final title = _titleController.text.trim();
    final bpm = double.tryParse(_bpmController.text.trim());

    if (title.isEmpty) {
      _showMessage('Ingresa el nombre de la canción.');
      return;
    }

    if (bpm == null || !bpm.isFinite || bpm <= 0 || bpm > 300) {
      _showMessage('Ingresa un BPM válido entre 1 y 300.');
      return;
    }

    if (_timeSignature == null || _originalKey == null) {
      _showMessage('Selecciona el compás y la tonalidad original.');
      return;
    }

    final song = widget.song;

    song.title = title;
    song.bpm = bpm;
    song.timeSignature = _timeSignature;
    song.originalKey = _originalKey;

    try {
      await _songStorage.saveSongConfiguration(song);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Error guardando configuración: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de canción'),
        actions: [
          IconButton(
            tooltip: 'Reproducir',
            icon: const Icon(Icons.play_circle),
            onPressed: () {
              songSession.setSong(song);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlayerPage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Mezclador',
            icon: const Icon(Icons.tune),
            onPressed: () {
              songSession.setSong(song);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MixerPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (song.artwork != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Image.file(
                File(song.artwork!.path),
                height: 180,
                fit: BoxFit.contain,
              ),
            ),

          _sectionTitle('Información de la canción'),

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la canción',
              prefixIcon: Icon(Icons.music_note),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _bpmController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'BPM',
              prefixIcon: Icon(Icons.speed),
              suffixText: 'BPM',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _timeSignature,
            decoration: const InputDecoration(
              labelText: 'Compás',
              prefixIcon: Icon(Icons.piano),
              border: OutlineInputBorder(),
            ),
            items: _timeSignatures.map((signature) {
              return DropdownMenuItem(
                value: signature,
                child: Text(signature),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _timeSignature = value);
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _originalKey,
            decoration: const InputDecoration(
              labelText: 'Tonalidad original',
              prefixIcon: Icon(Icons.graphic_eq),
              border: OutlineInputBorder(),
            ),
            items: _keys.map((key) {
              return DropdownMenuItem(
                value: key,
                child: Text(key),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _originalKey = value);
            },
          ),

          const SizedBox(height: 24),

          _sectionTitle('Análisis automático'),

          const Text(
            'Analiza las pistas WAV para obtener propuestas de BPM '
            'y tonalidad. Podrás corregir los resultados antes de guardar.',
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: _analyzing ? null : _analyzeAudio,
            icon: _analyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.analytics),
            label: Text(
              _analyzing
                  ? 'Analizando pistas...'
                  : 'Analizar audio automáticamente',
            ),
          ),

          if (_analysisResult != null) ...[
            const SizedBox(height: 16),
            _buildAnalysisResults(_analysisResult!),
          ],

          const SizedBox(height: 28),

          _sectionTitle('Pistas de audio'),

          ...song.audioTracks.map(_buildTrackEditor),

          const SizedBox(height: 28),

          _sectionTitle('Otros archivos'),

          _buildAssetSection(
            'MIDI',
            song.byType(SongAssetType.midi),
          ),
          _buildAssetSection(
            'Lyrics',
            song.byType(SongAssetType.lyrics),
          ),
          _buildAssetSection(
            'Chords',
            song.byType(SongAssetType.chords),
          ),
          _buildAssetSection(
            'Artwork',
            song.byType(SongAssetType.artwork),
          ),

          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: _saveConfiguration,
            icon: const Icon(Icons.save),
            label: const Text('Guardar configuración'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildTrackEditor(SongAsset asset) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: ValueKey(asset.path),
        initialValue: asset.name,
        onChanged: (value) {
          asset.name = value;
        },
        decoration: const InputDecoration(
          labelText: 'Nombre de pista',
          prefixIcon: Icon(Icons.audiotrack),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildAssetSection(String title, List<SongAsset> assets) {
    if (assets.isEmpty) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        title: Text(title),
        children: assets.map((asset) {
          return ListTile(
            title: Text(asset.name),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalysisResults(AudioAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados encontrados',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            if (result.suggestedBpm != null)
              Text(
                'BPM sugerido: ${result.suggestedBpm!.toStringAsFixed(1)}',
              ),

            if (result.keyCandidates.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Tonalidades detectadas:'),
              ...result.keyCandidates.map((key) {
                final name = key.split(' (').first;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    name == _originalKey
                        ? Icons.check_circle
                        : Icons.music_note,
                  ),
                  title: Text(name),
                  trailing: TextButton(
                    onPressed: () {
                      final selectedKey = name;

                      if (_keys.contains(selectedKey)) {
                        setState(() {
                          _originalKey = selectedKey;
                        });
                      }
                    },
                    child: const Text('Seleccionar'),
                  ),
                );
              }),
            ],

            const Divider(),

            Text(
              'Resultados por pista (${result.tracks.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),

            ...result.tracks.map((track) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(track.trackName),
                subtitle: Text(
                  '${track.bpm.toStringAsFixed(1)} BPM'
                  ' · ${track.camelotKey ?? "Sin tonalidad"}',
                ),
                trailing: Text(
                  '${(track.keyConfidence * 100).toStringAsFixed(0)}%',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}