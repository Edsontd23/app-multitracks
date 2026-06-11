import 'package:flutter/services.dart';

class DAWPlatform {
  static const _channel = MethodChannel('daw_engine');

  static final instance = DAWPlatform();

  Future<void> loadTracks(List<String> paths) async {
    await _channel.invokeMethod('loadTracks', {
      'paths': paths,
    });
  }

  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  Future<void> setVolume(int index,double volume) async {
    await _channel.invokeMethod(
      'setVolume',
      {
        'index': index,
        'volume': volume,
      },
    );
  }

  Future<void> mute( int index, bool enabled,) async {
    await _channel.invokeMethod(
      'mute',
      {
        'index': index,
        'enabled': enabled,
      },
    );
  }

  Future<void> solo(int index,bool enabled,) async {
    await _channel.invokeMethod(
      'solo',
      {
        'index': index,
        'enabled': enabled,
      },
    );
  }

  Future<void> seek(double seconds) async {
    await _channel.invokeMethod(
      'seek',
      {
        'seconds': seconds,
      },
    );
  }

  Future<double> position() async {
    return await _channel.invokeMethod(
      'position',
    );
  }

  Future<double> duration() async {
    return await _channel.invokeMethod(
      'duration',
    );
  }
}