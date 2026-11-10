class AudioTrackAnalysis {
  final String trackName;
  final double bpm;
  final String? camelotKey;
  final double keyConfidence;

  const AudioTrackAnalysis({
    required this.trackName,
    required this.bpm,
    this.camelotKey,
    required this.keyConfidence,
  });
}

class AudioAnalysisResult {
  final double? suggestedBpm;
  final String? suggestedKey;
  final List<String> keyCandidates;
  final List<AudioTrackAnalysis> tracks;

  const AudioAnalysisResult({
    required this.suggestedBpm,
    required this.suggestedKey,
    this.keyCandidates = const [],
    required this.tracks,
  });
}