
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../songs/domain/song_marker.dart';
import '../waveform/waveform.dart';
import 'timeline_grid_painter.dart';

class Timeline extends StatefulWidget {
  final Duration duration;
  final ValueListenable<Duration> positionListenable;
  final List<SongMarker> markers;
  final ScrollController scrollController;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onScrubStart,onScrubEnd;

  final Function(SongMarker marker, Duration newPosition)?onMarkerMoved;

  final void Function(SongMarker marker)? onRenameMarker;
  final void Function(SongMarker marker)? onDeleteMarker;
  final void Function(SongMarker marker)? onGoToMarker;
  final void Function(SongMarker marker)? onSetLoopStart;
  final void Function(SongMarker marker)? onSetLoopEnd;
  final void Function(SongMarker marker, int colorValue)? onChangeMarkerColor;

  final List<double>? waveform;

  final bool isPlaying;

  const Timeline({
    super.key,
    required this.duration,
    required this.positionListenable,
    required this.markers,
    required this.scrollController,
    required this.isPlaying,
    this.onMarkerMoved,
    this.waveform,
    this.onRenameMarker,
    this.onDeleteMarker,
    this.onGoToMarker,
    this.onSetLoopStart,
    this.onSetLoopEnd,
    this.onSeek,
    this.onScrubStart,
    this.onScrubEnd,
    this.onChangeMarkerColor,
  });

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  static const double _height = 100,_markerTop = 10,_waveformTop = 0,_markerWidth = 5;

  final Map<String, double> _dragPositions = {};

  double _durationSeconds = 0;

  List<SongMarker> get _sections {
  return widget.markers
      .where((marker) => marker.type == SongMarkerType.section)
      .toList()
    ..sort((a, b) => a.position.compareTo(b.position));
}

  double _xFromDuration(Duration position,double width,) {
    if (_durationSeconds <= 0) return 0;
    final seconds = position.inMilliseconds / 1000.0;
    return (seconds / _durationSeconds * width).clamp(0.0, width);
  }

  Duration _durationFromX(double x,double width) {
    if (_durationSeconds <= 0 || width <= 0) return Duration.zero;

    final percent = (x / width).clamp(0.0, 1.0);

    return Duration(milliseconds: (percent * widget.duration.inMilliseconds).round());
  }
  
  void _handleSeek(Offset localPosition,double width,) {
    if (width <= 0 || _durationSeconds <= 0) return;

    final position = _durationFromX(localPosition.dx,width,);
    widget.onSeek?.call(position);
  }

  Widget _buildSeekArea(double width) {
    return Positioned(
      left: 0,
      right: 0,
      top: _waveformTop,
      bottom: 10,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTapDown: widget.isPlaying
            ? null
            : (details) {
                _handleSeek(details.localPosition, width);
              },

        onHorizontalDragStart: widget.isPlaying
            ? null
            : (details) {
                widget.onScrubStart?.call();
                _handleSeek(details.localPosition, width);
              },

        onHorizontalDragUpdate: widget.isPlaying
            ? null
            : (details) {
                _handleSeek(details.localPosition, width);
              },

        onHorizontalDragEnd: widget.isPlaying
            ? null
            : (_) {
                widget.onScrubEnd?.call();
              },

        onHorizontalDragCancel: widget.isPlaying
            ? null
            : () {
                widget.onScrubEnd?.call();
              },

        child: const SizedBox.expand(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    _durationSeconds = widget.duration.inMilliseconds / 1000.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width <= 0) return const SizedBox( height: _height, );

        return Container(
          height: _height,
          color: Colors.black87,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Cuadrícula
                Positioned.fill(
                  child: CustomPaint(
                    painter: TimelineGridPainter(
                      duration: widget.duration,
                    ),
                  ),
                ),

                // Waveform
                Positioned(
                  left: 0,
                  right: 0,
                  top: _waveformTop,
                  bottom: 10,
                  child: Waveform(
                    samples: widget.waveform ?? [],
                  ),
                ),

                // Segmentos
                _buildSegments(width),

                // Navegación mediante waveform
                _buildSeekArea(width),

                // Nombres
                _buildSegmentLabels(width),

                // Marcadores
                _buildMarkers(width),

                // Cabezal
                ValueListenableBuilder<Duration>(
                  valueListenable: widget.positionListenable,
                  builder: (context, position, child) {
                    return _buildPlayhead(width, position);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegments(double width) {
    if (_durationSeconds <= 0 || width <= 0) {
      return const SizedBox.shrink();
    }

    final sortedMarkers = _sections;

    final boundaries = <double>[0];

    // Identificar la sección que comienza en el segundo cero.
    SongMarker? initialMarker;

    for (final marker in sortedMarkers) {
      if (marker.position == Duration.zero) {
        initialMarker = marker;
        break;
      }
    }

    // Cada elemento corresponde al segmento que comienza
    // en el límite agregado en la misma posición.
    final sectionMarkers = <SongMarker?>[initialMarker];

    for (final marker in sortedMarkers) {
      final x = _xFromDuration(marker.position, width);

      if (x > boundaries.last && x < width) {
        boundaries.add(x);
        sectionMarkers.add(marker);
      }
    }

    boundaries.add(width);

    return Stack(
      children: List.generate(boundaries.length - 1, (index) {
        final start = boundaries[index];
        final end = boundaries[index + 1];

        final color = Color(
          sectionMarkers[index]?.colorValue ?? 0xFF64748B,
        );

        return Positioned(
          left: start,
          top: _waveformTop,
          width: end - start,
          bottom: 10,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5),
              border: Border(
                left: BorderSide(
                  color: color,
                  width: 2,
                ),
                right: BorderSide(
                  color: color.withValues(alpha: 0.75),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSegmentLabels(double width) {
    if (_durationSeconds <= 0 || width <= 0) {
      return const SizedBox.shrink();
    }

    final sortedMarkers = _sections;

    final boundaries = <double>[0];
    final sectionMarkers = <SongMarker?>[];

    SongMarker? initialSection;

    for (final section in sortedMarkers) {
      if (section.position == Duration.zero) {
        initialSection = section;
        break;
      }
    }

    sectionMarkers.add(initialSection);

    for (final section in sortedMarkers) {
      final x = _xFromDuration(section.position, width);

      if (x > boundaries.last && x < width) {
        boundaries.add(x);
        sectionMarkers.add(section);
      }
    }

    boundaries.add(width);

    return Stack(
      children: List.generate(boundaries.length - 1, (index) {
        final start = boundaries[index];
        final end = boundaries[index + 1];
        final segmentWidth = end - start;

        if (segmentWidth < 55) {
          return const SizedBox.shrink();
        }

        final section = sectionMarkers[index];

        final name = section?.name ?? 'Inicio';

        final color = section != null
            ? Color(section.colorValue)
            : const Color(0xFF64748B);

        return Positioned(
          left: start + 4,
          top: _waveformTop + 3,
          width: segmentWidth - 8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPlayhead(double width, Duration position) {
    final x = _xFromDuration(position, width);

    return Positioned(
      left: x.clamp(0.0, width - 2),
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        color: Colors.redAccent,
      ),
    );
  }

  Widget _buildMarkers(double width) {
    final sortedMarkers = [...widget.markers]
      ..sort(
        (a, b) => a.position.compareTo(b.position),
      );

    return Stack(
      clipBehavior: Clip.none,
      children: sortedMarkers.map((marker) {
        final x = _dragPositions[marker.id] ?? _xFromDuration(marker.position, width);

        return Positioned(
          left: (x - _markerWidth / 2).clamp(0.0, width - _markerWidth),
          top: _markerTop,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapDown: widget.isPlaying ? null : (details) {_showMarkerMenu(context, details.globalPosition, marker);},
            onLongPressStart: widget.isPlaying ? null : (details) { _showMarkerMenu(context, details.globalPosition, marker);},
            onPanStart: widget.isPlaying
                ? null
                : (_) {
                    _dragPositions[marker.id] = x;
                  },

            onPanUpdate: widget.isPlaying
                ? null
                : (details) {
                    final currentX = _dragPositions[marker.id] ?? x;

                    final newX = (currentX + details.delta.dx).clamp(0.0, width);

                    setState(() {
                      _dragPositions[marker.id] = newX;
                    });

                    widget.onMarkerMoved?.call(
                      marker,
                      _durationFromX(newX, width),
                    );
                  },

            onPanEnd: widget.isPlaying
                ? null
                : (_) {
                    setState(() {
                      _dragPositions.remove(marker.id);
                    });
                  },

            child: SizedBox(
              width: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    marker.type == SongMarkerType.section
                        ? Icons.bookmark
                        : Icons.flag,
                    color: marker.type == SongMarkerType.section
                        ? Color(marker.colorValue)
                        : Colors.orange,
                    size: 20,
                  ),
                  Text(
                    marker.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: marker.type == SongMarkerType.section
                          ? Color(marker.colorValue)
                          : Colors.white,
                      fontSize: 10,
                      fontWeight: marker.type == SongMarkerType.section
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showMarkerMenu(
    BuildContext context,
    Offset position,
    SongMarker marker,
  ) async {
    final isSection = marker.type == SongMarkerType.section;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'rename',
          child: Text('✏️ Renombrar'),
        ),
        if (isSection)
          const PopupMenuItem(
            value: 'color',
            child: Text('🎨 Cambiar color'),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('🗑 Eliminar'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'goto',
          child: Text('📍 Ir aquí'),
        ),
      ],
    );

    if (!mounted) return;

    switch (value) {
      case 'rename':
        widget.onRenameMarker?.call(marker);
        break;

      case 'color':
        final colors = [
          const Color(0xFF64748B),
          const Color(0xFF287DB8),
          const Color(0xFF198B70),
          const Color(0xFF8B65B5),
          const Color(0xFFB77935),
          const Color(0xFFB84D68),
          const Color(0xFFB84D9A),
          const Color(0xFF398BBA),
        ];

        final selectedColor = await showDialog<int>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Color de sección'),
              content: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((color) {
                  final colorValue = color.toARGB32();
                  final selected = marker.colorValue == colorValue;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(dialogContext, colorValue);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: Theme.of(dialogContext)
                                    .colorScheme
                                    .onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );

        if (selectedColor != null && mounted) {
          widget.onChangeMarkerColor?.call(marker, selectedColor);
        }
        break;

      case 'delete':
        widget.onDeleteMarker?.call(marker);
        break;

      case 'goto':
        widget.onGoToMarker?.call(marker);
        break;
    }
  }
}
