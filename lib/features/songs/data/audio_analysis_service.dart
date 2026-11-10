import 'package:flutter/foundation.dart';
import 'package:music_analysis/music_analysis.dart';

import '../domain/song.dart';
import '../domain/audio_analysis_result.dart';

class AudioAnalysisService {
  static const double _bpmTolerance = 3.0;

  static const Map<String, String> _camelotToKey = {
    '1A': 'G# menor',
    '1B': 'B mayor',
    '2A': 'D# menor',
    '2B': 'F# mayor',
    '3A': 'A# menor',
    '3B': 'C# mayor',
    '4A': 'F menor',
    '4B': 'G# mayor',
    '5A': 'C menor',
    '5B': 'D# mayor',
    '6A': 'G menor',
    '6B': 'A# mayor',
    '7A': 'D menor',
    '7B': 'F mayor',
    '8A': 'A menor',
    '8B': 'C mayor',
    '9A': 'E menor',
    '9B': 'G mayor',
    '10A': 'B menor',
    '10B': 'D mayor',
    '11A': 'F# menor',
    '11B': 'A mayor',
    '12A': 'C# menor',
    '12B': 'E mayor',
  };

  Future<AudioAnalysisResult> analyzeSong(Song song) async {
    final wavTracks = song.audioTracks
        .where((track) => track.path.toLowerCase().endsWith('.wav'))
        .toList();

    if (wavTracks.isEmpty) {
      throw Exception('La canción no contiene pistas WAV.');
    }

    final results = <AudioTrackAnalysis>[];

    for (final track in wavTracks) {
      try {
        debugPrint('Analizando: ${track.name}');

        final result = await Music.analyzeFile(track.path);

        final bpm = result.musicData.bpm;
        final prediction = result.musicData.key.bestPrediction;

        if (!bpm.isFinite || bpm <= 0) {
          continue;
        }

        // Extraemos el código Camelot, por ejemplo: 10B.
        final keyMatch = RegExp(
          r'\b(1[0-2]|[1-9])[AB]\b',
        ).firstMatch(prediction.toString());

        final camelotKey = keyMatch?.group(0);

        results.add(
          AudioTrackAnalysis(
            trackName: track.name,
            bpm: bpm,
            camelotKey: camelotKey,
            keyConfidence: prediction.confidence,
          ),
        );

        debugPrint(
          '${track.name}: ${bpm.toStringAsFixed(2)} BPM | '
          '${camelotKey ?? "Sin tonalidad"} | '
          '${(prediction.confidence * 100).toStringAsFixed(1)}%',
        );
      } catch (e) {
        // Un error individual no detiene el análisis de las demás pistas.
        debugPrint('Error analizando ${track.name}: $e');
      }
    }

    if (results.isEmpty) {
      throw Exception('No fue posible analizar ninguna pista WAV.');
    }

    final suggestedBpm = _calculateBpm(results);
    final keyCandidates = _calculateKeys(results);

    return AudioAnalysisResult(
      suggestedBpm: suggestedBpm,
      suggestedKey: keyCandidates.isEmpty ? null : keyCandidates.first,
      keyCandidates: keyCandidates,
      tracks: results,
    );
  }

  // --------------------------------------------------
  // BPM
  // --------------------------------------------------

  double? _calculateBpm(List<AudioTrackAnalysis> tracks) {
    final candidates = tracks
        .where((track) => _bpmWeight(track.trackName) > 0)
        .toList();

    if (candidates.isEmpty) return null;

    List<AudioTrackAnalysis>? bestCluster;
    double bestWeight = -1;

    for (final seed in candidates) {
      final cluster = candidates.where((track) {
        return (track.bpm - seed.bpm).abs() <= _bpmTolerance;
      }).toList();

      final weight = cluster.fold<double>(
        0,
        (total, track) => total + _bpmWeight(track.trackName),
      );

      if (weight > bestWeight ||
          (weight == bestWeight &&
              cluster.length > (bestCluster?.length ?? 0))) {
        bestWeight = weight;
        bestCluster = cluster;
      }
    }

    if (bestCluster == null || bestCluster.isEmpty) return null;

    return _weightedMedian(
      bestCluster,
      (track) => track.bpm,
      (track) => _bpmWeight(track.trackName),
    );
  }

  double _bpmWeight(String trackName) {
    final name = trackName.toLowerCase();

    if (name.contains('fx')) return 0;
    if (name.contains('click')) return 3.0;
    if (name.contains('drum')) return 2.5;
    if (name.contains('perc')) return 1.8;

    if (name.contains('guide')) return 0.25;
    if (name.contains('bgv') || name.contains('vocal')) return 0.3;

    if (name.contains('bass')) return 1.2;

    if (name.contains('piano') ||
        name.contains('keys') ||
        name.contains('ag') ||
        name.contains('eg') ||
        name.contains('guitar') ||
        name.contains('strings')) {
      return 1.0;
    }

    return 0.6;
  }

  double _weightedMedian(
    List<AudioTrackAnalysis> tracks,
    double Function(AudioTrackAnalysis) getValue,
    double Function(AudioTrackAnalysis) getWeight,
  ) {
    final sorted = [...tracks]
      ..sort((a, b) => getValue(a).compareTo(getValue(b)));

    final totalWeight = sorted.fold<double>(
      0,
      (total, track) => total + getWeight(track),
    );

    final midpoint = totalWeight / 2;
    double accumulated = 0;

    for (final track in sorted) {
      accumulated += getWeight(track);

      if (accumulated >= midpoint) {
        return getValue(track);
      }
    }

    return getValue(sorted.last);
  }

  // --------------------------------------------------
  // TONALIDAD
  // --------------------------------------------------

  List<String> _calculateKeys(List<AudioTrackAnalysis> tracks) {
    final scores = <String, double>{};

    for (final track in tracks) {
      final camelot = track.camelotKey;

      if (camelot == null) continue;

      final weight = _keyWeight(track.trackName);

      if (weight <= 0) continue;

      final confidence = track.keyConfidence.clamp(0.0, 1.0);

      scores[camelot] =
          (scores[camelot] ?? 0) + (confidence * weight);
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .map((entry) {
          final name = _camelotToKey[entry.key];
          return name == null ? entry.key : '$name (${entry.key})';
        })
        .toList();
  }

  double _keyWeight(String trackName) {
    final name = trackName.toLowerCase();

    if (name.contains('fx') ||
        name.contains('click') ||
        name.contains('drum') ||
        name.contains('perc')) {
      return 0;
    }

    if (name.contains('guide')) return 0;
    if (name.contains('bgv') || name.contains('vocal')) return 0.25;

    if (name.contains('piano') ||
        name.contains('keys') ||
        name.contains('ag') ||
        name.contains('eg') ||
        name.contains('guitar') ||
        name.contains('bass') ||
        name.contains('strings')) {
      return 1.0;
    }

    return 0.5;
  }
}