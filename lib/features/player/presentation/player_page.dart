import 'dart:io';
import 'dart:async';
import 'package:app_multitracks/core/audio/daw_platform.dart';
import 'package:app_multitracks/core/theme/app_colors.dart';
import 'package:app_multitracks/core/tracks/track_mapper.dart';
import 'package:app_multitracks/features/songs/domain/song_asset_type.dart';
import 'package:app_multitracks/features/songs/domain/song_marker.dart';
import 'package:app_multitracks/features/songs/application/song_marker_controller.dart';
import 'package:flutter/material.dart';

import '../../../core/audio/master_mixer.dart';
import '../../../core/audio/waveform_service.dart';
import '../../../core/session/session_instance.dart';
import '../../player/domain/track_player.dart';
import '../domain/audio_clip.dart';
import 'widgets/timeline/timeline.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool loaded = false;
  List<double> volumes = [];
  List<TrackModel> tracks = [];
  List<bool> muted = [], soloed = [];
  bool isPlaying = false, loopEnabled = false;
  Duration? loopStartPosition,loopEndPosition;
  Timer? positionTimer;
  Duration currentPosition = Duration.zero, totalDuration = Duration.zero;
  late final SongMarkerController markerController;
  List<SongMarker> get markers => markerController.markers;
  final ScrollController timelineController = ScrollController();
  bool _markerControllerInitialized = false;
  bool _isScrubbing = false;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  bool _isReadingPosition = false;
  SongMarker? _pendingMarker;
  Duration? _pendingMarkerBoundary;
  int transposeSemitones = 0;
  bool isChangingTranspose = false;

  double get playheadX {
    if (totalDuration.inMilliseconds == 0) return 0;

    return ( currentPosition.inMilliseconds / totalDuration.inMilliseconds ) * ( totalDuration.inMilliseconds / 1000 * 100 );
  }
  
  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startPositionTimer() {
    positionTimer?.cancel();

    positionTimer = Timer.periodic(
      const Duration(milliseconds: 25),
      (_) async {
        if (!mounted || _isScrubbing || _isReadingPosition) return;

        _isReadingPosition = true;

        try {
          final seconds = await DAWPlatform.instance.position();

          if (!mounted || _isScrubbing) return;

          currentPosition = Duration(
            milliseconds: (seconds * 1000).round(),
          );

          

          if (_pendingMarker != null &&
              _pendingMarkerBoundary != null &&
              currentPosition >= _pendingMarkerBoundary!) {

            final target = _pendingMarker!;

            // Limpiar la cola.
            _pendingMarker = null;
            _pendingMarkerBoundary = null;

            // Ejecutar el salto.
            await _seekToPosition(target.position);

            currentPosition = target.position;
          }

          positionNotifier.value = currentPosition;
        } catch (error) {
          debugPrint('Error consultando posición: $error');
        } finally {
          _isReadingPosition = false;
        }
      },
    );
  }

  Future<void> loadMasterWaveform() async {
    final song = songSession.currentSong;
    if(song == null) return;
    final waveformService = WaveformService();
    final master = await waveformService.generate( song.audioTracks.first.path);
    song.waveform =master;
    setState((){});
  }

  Future<void> _seekToPosition(Duration position) async {
    final milliseconds = position.inMilliseconds
        .clamp(0, totalDuration.inMilliseconds)
        .toInt();

    final newPosition = Duration(milliseconds: milliseconds);

    currentPosition = newPosition;
    positionNotifier.value = newPosition;

    await DAWPlatform.instance.seek(
      newPosition.inMilliseconds / 1000.0,
    );
  }

  // MARK: - LOOP START
  Future<void> _setLoopStart(SongMarker marker) async {
    try {
      final position = marker.position;

      if (loopEndPosition != null &&
          position >= loopEndPosition!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loop Start debe estar antes de Loop End'),
          ),
        );
        return;
      }

      await DAWPlatform.instance.setLoopStart(
        position.inMicroseconds /
            Duration.microsecondsPerSecond,
      );

      if (!mounted) return;

      setState(() {
        loopStartPosition = position;
      });

      debugPrint('🔁 Loop Start: ${marker.name}');
    } catch (error) {
      debugPrint('Error estableciendo Loop Start: $error');
    }
  }

  // MARK: - LOOP END
  Future<void> _setLoopEnd(SongMarker marker) async {
    try {
      final position = marker.position;

      if (loopStartPosition == null ||
          position <= loopStartPosition!) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loop End debe estar después de Loop Start'),
          ),
        );
        return;
      }

      await DAWPlatform.instance.setLoopEnd(
        position.inMicroseconds /
            Duration.microsecondsPerSecond,
      );

      if (!mounted) return;

      setState(() {
        loopEndPosition = position;
      });

      debugPrint('🔁 Loop End: ${marker.name}');
    } catch (error) {
      debugPrint('Error estableciendo Loop End: $error');
    }
  }

  // MARK: - TOGGLE LOOP
  Future<void> _toggleLoop() async {
    try {
      // Si el loop está activo, lo desactivamos.
      if (loopEnabled) {
        await DAWPlatform.instance.setLoopEnabled(false);

        if (!mounted) return;

        setState(() {
          loopEnabled = false;
          loopStartPosition = null;
          loopEndPosition = null;
        });

        return;
      }

      // Obtener los límites de la sección actual.
      final bounds = _getCurrentSegmentBounds();

      if (bounds.end <= bounds.start) {
        debugPrint('La sección seleccionada no tiene una duración válida.');
        return;
      }

      // Configurar el intervalo en el motor de audio.
      await DAWPlatform.instance.setLoopStart(
        bounds.start.inMilliseconds / 1000.0,
      );

      await DAWPlatform.instance.setLoopEnd(
        bounds.end.inMilliseconds / 1000.0,
      );

      await DAWPlatform.instance.setLoopEnabled(true);

      if (!mounted) return;

      setState(() {
        loopEnabled = true;
        loopStartPosition = bounds.start;
        loopEndPosition = bounds.end;
      });

      debugPrint(
        'Loop activado: ${formatDuration(bounds.start)} - '
        '${formatDuration(bounds.end)}',
      );
    } catch (error, stackTrace) {
      debugPrint('Error configurando loop: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _togglePlayback() async {
    if (isPlaying) {
      await DAWPlatform.instance.pause();

      final seconds = await DAWPlatform.instance.position();

      positionTimer?.cancel();

      if (!mounted) return;

      setState(() {
        isPlaying = false;
        currentPosition = Duration(
          milliseconds: (seconds * 1000).round(),
        );
        positionNotifier.value = currentPosition;
      });

      return;
    }

    await DAWPlatform.instance.play();

    if (!mounted) return;

    _startPositionTimer();

    setState(() {
      isPlaying = true;
    });
  }

  Future<void> _stopPlayback() async {
    await DAWPlatform.instance.stop();

    positionTimer?.cancel();

    if (!mounted) return;

    setState(() {
      isPlaying = false;
      currentPosition = Duration.zero;
      positionNotifier.value = Duration.zero;

      _pendingMarker = null;
      _pendingMarkerBoundary = null;
    });
  }

  Future<void> _onMarkerPressed(SongMarker marker) async {
    // Si es un marcador normal, navegar inmediatamente.
    if (marker.type == SongMarkerType.marker) {
      _pendingMarker = null;
      _pendingMarkerBoundary = null;
      await _seekToPosition(marker.position);
      return;
    }

    // Si está pausado, navegar inmediatamente.
    if (!isPlaying) {
      _pendingMarker = null;
      _pendingMarkerBoundary = null;
      await _seekToPosition(marker.position);
      return;
    }

    // Guardar el último destino solicitado.
    _pendingMarker = marker;

    // Si ya existe un salto pendiente, conservar el límite actual.
    if (_pendingMarkerBoundary != null) return;

    // Obtener exclusivamente las secciones.
    final sections = markers
        .where((item) => item.type == SongMarkerType.section)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // Encontrar el siguiente límite de sección.
    SongMarker? nextSection;

    for (final section in sections) {
      if (section.position > currentPosition) {
        nextSection = section;
        break;
      }
    }

    _pendingMarkerBoundary = nextSection?.position ?? totalDuration;
  }

  ({Duration start, Duration end}) _getCurrentSegmentBounds() {
    final sortedMarkers = [...markers]
      ..sort((a, b) => a.position.compareTo(b.position));

    final previousMarkers = sortedMarkers.where((marker) => marker.position <= currentPosition).toList();
    final nextMarkers = sortedMarkers.where((marker) => marker.position > currentPosition).toList();

    final start = previousMarkers.isNotEmpty ? previousMarkers.last.position : Duration.zero;
    final end = nextMarkers.isNotEmpty ? nextMarkers.first.position : totalDuration;

    return (start: start, end: end);
  }

  Future<void> _setTranspose(int semitones) async {
    if (isChangingTranspose) return;

    setState(() {
      isChangingTranspose = true;
    });

    try {
      await DAWPlatform.instance.setTranspose(semitones);

      if (!mounted) return;

      setState(() {
        transposeSemitones = semitones;
      });

      debugPrint('🎹 Transposición: $semitones semitonos');
    } catch (error) {
      debugPrint('Error aplicando transposición: $error');
    } finally {
      if (mounted) {
        setState(() {
          isChangingTranspose = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final song = songSession.currentSong;

    if (song == null) return;

    tracks = song.audioTracks.map((asset) {
      return TrackModel(
        name: asset.name,
        path: asset.path,
        style: TrackMapper.fromName(asset.name),
        clips: [
          AudioClip(
            id: asset.path,
            name: asset.name.split('.').first,
            start: Duration.zero,
            duration: totalDuration,
            color: TrackMapper.fromName(asset.name).color,
          ),
        ],
      );
    }).toList();

    markerController = SongMarkerController(song: song);
    _markerControllerInitialized = true;

    muted = List.generate(tracks.length, (_) => false);
    soloed = List.generate(tracks.length, (_) => false);
    volumes = List.generate(tracks.length, (_) => 1.0);

    final paths = song.assets
        .where((asset) => asset.type == SongAssetType.audio)
        .map((asset) => asset.path)
        .toList();

    await DAWPlatform.instance.loadTracks(paths);

    if (!mounted) return;

    final masterPath = await MasterMixer().mix(paths);

    if (!mounted) return;

    song.waveform = await WaveformService().generate(masterPath);

    if (!mounted) return;

    final seconds = await DAWPlatform.instance.duration();

    if (!mounted) return;

    totalDuration = Duration(
      milliseconds: (seconds * 1000).toInt(),
    );

    setState(() {
      loaded = true;
    });
  }

  @override
  void dispose() {
    positionTimer?.cancel();

    if (_markerControllerInitialized) {
      unawaited(
        markerController.dispose().catchError((Object error) {
          debugPrint('Error al liberar marcadores: $error');
        }),
      );
    }

    timelineController.dispose();
    positionNotifier.dispose();
    super.dispose();
  }

  Future<void> _addMarker() async {
    final nameController = TextEditingController(
      text: 'Sección ${markers.length + 1}',
    );

    const sectionColors = [
      Color(0xFF64748B), // Gris
      Color(0xFF287DB8), // Azul
      Color(0xFF198B70), // Verde
      Color(0xFF8B65B5), // Morado
      Color(0xFFB77935), // Naranja
      Color(0xFFB84D68), // Rosa
    ];

    int selectedColor = sectionColors.first.toARGB32();

    final marker = await showDialog<SongMarker>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva sección'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la sección',
                      hintText: 'Ej. Verso 1',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Color'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: sectionColors.map((color) {
                      final colorValue = color.toARGB32();

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = colorValue;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == colorValue
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();

                    if (name.isEmpty) return;

                    Navigator.pop(
                      dialogContext,
                      SongMarker(
                        id: DateTime.now()
                            .microsecondsSinceEpoch
                            .toString(),
                        name: name,
                        position: currentPosition,
                        beat: 0,
                        measure: 0,
                        tick: 0,
                        type: SongMarkerType.section,
                        colorValue: selectedColor,
                      ),
                    );
                  },
                  child: const Text('Crear sección'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (marker == null || !mounted) return;

    setState(() {
      markerController.addMarker(marker);
    });

    await markerController.saveNow();
  }

  Future<void> _addSection() async {
    const colors = [
      Color(0xFF64748B),
      Color(0xFF287DB8),
      Color(0xFF198B70),
      Color(0xFF8B65B5),
      Color(0xFFB77935),
      Color(0xFFB84D68),
      Color(0xFFB84D9A),
      Color(0xFF398BBA),
    ];

    final sectionCount = markers
        .where((marker) => marker.type == SongMarkerType.section)
        .length;

    final nameController = TextEditingController(
      text: 'Sección ${sectionCount + 1}',
    );

    int selectedColor = colors[sectionCount % colors.length].toARGB32();

    final result = await showDialog<SongMarker>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva sección'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la sección',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Color'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colors.map((color) {
                      final colorValue = color.toARGB32();
                      final selected = selectedColor == colorValue;

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = colorValue;
                          });
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();

                    if (name.isEmpty) return;

                    Navigator.pop(
                      dialogContext,
                      SongMarker(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        position: currentPosition,
                        beat: 0,
                        measure: 0,
                        tick: 0,
                        type: SongMarkerType.section,
                        colorValue: selectedColor,
                      ),
                    );
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      markerController.addMarker(result);
    });

    await markerController.saveNow();
  }

  Future<void> _renameMarker(SongMarker marker) async {
    final controller = TextEditingController(text: marker.name);

    final isSection = marker.type == SongMarkerType.section;

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isSection ? 'Renombrar sección' : 'Renombrar marcador',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: isSection ? 'Nombre de la sección' : 'Nombre del marcador',
              hintText: isSection ? 'Ej. Coro 1' : 'Ej. Intro guitarra',
            ),
            onSubmitted: (value) {
              final name = value.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, name);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isEmpty) return;

                Navigator.pop(dialogContext, name);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || newName == null || newName.isEmpty) return;

    setState(() {
      markerController.renameMarker(marker, newName);
    });

    await markerController.saveNow();
  }

  Future<void> _deleteMarker(SongMarker marker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            marker.type == SongMarkerType.section
                ? 'Eliminar sección'
                : 'Eliminar marcador',
          ),
          content: Text(
            '¿Deseas eliminar "${marker.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      markerController.deleteMarker(marker);

      // Si el destino pendiente fue eliminado, cancelarlo.
      if (_pendingMarker?.id == marker.id) {
        _pendingMarker = null;
        _pendingMarkerBoundary = null;
      }

      // Si se eliminó una sección, recalcular el límite pendiente.
      else if (marker.type == SongMarkerType.section &&
          _pendingMarker != null &&
          _pendingMarkerBoundary == marker.position) {
        _pendingMarkerBoundary = _nextSectionBoundary();
      }
    });

    await markerController.saveNow();
  }

  Duration _nextSectionBoundary() {
    final sections = markers
        .where((item) => item.type == SongMarkerType.section)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    for (final section in sections) {
      if (section.position > currentPosition) {
        return section.position;
      }
    }

    return totalDuration;
  }

  Future<void> _goToMarker(SongMarker marker) async {
    final position = Duration(
      milliseconds: marker.position.inMilliseconds.clamp(
        0,
        totalDuration.inMilliseconds,
      ),
    );

    try {
      await DAWPlatform.instance.seek(
        position.inMicroseconds / Duration.microsecondsPerSecond,
      );

      if (!mounted) return;

      currentPosition = position;
      positionNotifier.value = position;
    } catch (error) {
      debugPrint('Error navegando al marcador: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = songSession.currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center( child: Text('No song selected'), ),
      );
    }

    if (!loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            collapsedHeight: 75,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (song.artwork != null)
                    Image.file(
                      File(song.artwork!.path),
                      fit: BoxFit.cover,
                    ),

                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 60,
                    right: 16,
                    bottom: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            ValueListenableBuilder<Duration>(
                              valueListenable: positionNotifier,
                              builder: (context, position, child) {
                                return Text(
                                  formatDuration(position),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                              onPressed: isPlaying ? null : _addSection,
                            ),
                            IconButton(
                              tooltip: loopEnabled ? 'Desactivar loop' : 'Activar loop',
                              onPressed: _toggleLoop,
                              icon: Icon(
                                Icons.repeat,
                                color: loopEnabled
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                            Text(
                              formatDuration(totalDuration),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                            // Play / Pause
                            IconButton(
                              tooltip: isPlaying ? 'Pausar' : 'Reproducir',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(32, 32),
                                maximumSize: const Size(32, 32),
                              ),
                              onPressed: _togglePlayback,
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Stop
                            IconButton(
                              tooltip: 'Detener',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade800,
                                shape: const CircleBorder(),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(32, 32),
                                maximumSize: const Size(32, 32),
                              ),
                              onPressed: _stopPlayback,
                              icon: const Icon(
                                Icons.stop,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Bajar un semitono',
                              onPressed: isChangingTranspose || transposeSemitones <= -12
                                  ? null
                                  : () => _setTranspose(transposeSemitones - 1),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.white,
                              ),
                            ),

                            Text(
                              '${transposeSemitones > 0 ? '+' : ''}$transposeSemitones st',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            IconButton(
                              tooltip: 'Subir un semitono',
                              onPressed: isChangingTranspose || transposeSemitones >= 12
                                  ? null
                                  : () => _setTranspose(transposeSemitones + 1),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 12),

                            TextButton(
                              onPressed: isChangingTranspose || transposeSemitones == 0
                                  ? null
                                  : () => _setTranspose(0),
                              child: const Text(
                                'Original',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: markers.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, index) {
                              final marker = markers[index];
                              return FilledButton(
                                onPressed: () => _onMarkerPressed(marker),
                                child: Text(
                                  marker.name,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ), 
          ),
          SliverToBoxAdapter(
            // child: const SizedBox.shrink(),
            child: Timeline(
              duration: totalDuration,
              positionListenable: positionNotifier,
              markers: markers,
              scrollController: timelineController,
              waveform: song.waveform,
              onSeek: _seekToPosition,
              isPlaying: isPlaying,
              onChangeMarkerColor: (marker, colorValue) async {
                setState(() {
                  marker.colorValue = colorValue;
                });

                await markerController.saveNow();
              },
              onScrubStart: () {
                _isScrubbing = true;
              },
              onScrubEnd: () {
                _isScrubbing = false;
              },
              onMarkerMoved: (marker, newPosition) {
                setState(() {
                  markerController.moveMarker(marker, newPosition);
                });

                markerController.scheduleSave();
              },
              onRenameMarker: _renameMarker,
              onDeleteMarker: _deleteMarker,
              onGoToMarker: _goToMarker,
              onSetLoopStart: _setLoopStart,
              onSetLoopEnd: _setLoopEnd,
            ),
          ),
          SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 8,
              childAspectRatio:0.75,
            ),
            itemCount: tracks.length,
            itemBuilder: (BuildContext context, int index) {
              final track = tracks[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      // Track Name
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: track.style.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              track.style.icon,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            track.name.split('.').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Mute and Solo Buttons
                      const SizedBox(height: 8),
                      Row(
                        children:[
                          GestureDetector(
                            onTap: () async {
                              final value = !muted[index];

                              setState(() {
                                muted[index] = value;
                              });

                              await DAWPlatform.instance.mute(index,value,);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: muted[index] ? Colors.red : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.red,
                                ),
                              ),
                              child: const Text(
                                'M',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {

                              final value = !soloed[index];

                              setState(() {
                                soloed[index] = value;
                              });

                              await DAWPlatform.instance.solo(
                                index,
                                value,
                              );
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: soloed[index]
                                    ? Colors.amber
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.amber,
                                ),
                              ),
                              child: const Text(
                                'S',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ),
                      // Volume Slider
                      RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          min: 0,
                          max: 1,
                          value: track.volume,
                          onChanged: (value) async {
                            setState(() {
                              track.volume = value;
                            });
                            await DAWPlatform.instance.setVolume(
                              index,
                              value,
                            );
                          },
                        ),
                      )
                    ],
                  ),
              ),
            );
          }),
        ],
      ),
    );
  }
}