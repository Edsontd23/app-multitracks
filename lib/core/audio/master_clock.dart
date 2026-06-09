class MasterClock {
  DateTime? _startTime;

  Duration get position {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  DateTime start({int offsetMs = 200}) {
    _startTime = DateTime.now().add(
      Duration(milliseconds: offsetMs),
    );
    return _startTime!;
  }

  void reset() {
    _startTime = null;
  }

  bool get isRunning => _startTime != null;
}