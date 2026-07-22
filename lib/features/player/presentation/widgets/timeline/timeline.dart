import 'package:flutter/material.dart';
import '../../../../songs/domain/song_marker.dart';
import '../waveform/waveform.dart';
import 'timeline_grid_painter.dart';


class Timeline extends StatefulWidget {

  final Duration duration;
  final Duration position;
  final List<SongMarker> markers;
  final ScrollController scrollController;
  final List<double>? waveform;


  const Timeline({
    super.key,
    required this.duration,
    required this.position,
    required this.markers,
    required this.scrollController, 
    this.waveform,
  });

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  double pixelsPerSecond = 100;
  late final ScrollController scrollController;
  @override
  Widget build(BuildContext context) {
    debugPrint(
      "WAVEFORM LENGTH: ${widget.waveform?.length}"
    );
    final totalWidth =
        widget.duration.inSeconds * pixelsPerSecond;

    return Container(
      height: 120,
      color: Colors.black87,


      child: SingleChildScrollView(
        controller: widget.scrollController,
        scrollDirection: Axis.horizontal,


        child: SizedBox(

          width: totalWidth < MediaQuery.of(context).size.width
              ? MediaQuery.of(context).size.width
              : totalWidth,


          child: Stack(
            children: [

              CustomPaint(
                size: Size(
                  totalWidth,
                  120,
                ),
                painter: TimelineGridPainter(
                  pixelsPerSecond: pixelsPerSecond,
                ),
              ),


              Positioned(
                left:0,
                right:0,
                top:20,
                bottom:10,

                child: Waveform(
                  samples: widget.waveform ?? [],
                ),
              ),


              _buildRuler(),

              _buildMarkers(),

              _buildPlayhead(),

            ],
            ),

        ),
      ),
    );
  }

  Widget _buildRuler(){


    final seconds =
        widget.duration.inSeconds;


    return Stack(

      children: List.generate(
        seconds + 1,

        (index){

          return Positioned(

            left: index * pixelsPerSecond,

            top: 5,

            child: Text(
              "${index}s",

              style:
              const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          );

        },
      ),
    );

  }

  Widget _buildPlayhead(){


    final percent =
        widget.duration.inMilliseconds == 0
        ? 0
        :
        widget.position.inMilliseconds /
        widget.duration.inMilliseconds;


    return Positioned(

      left: percent *
          widget.duration.inSeconds *
          pixelsPerSecond,


      top: 0,

      bottom: 0,


      child: Container(

        width: 2,

        color: Colors.red,

      ),
    );
  }

  Widget _buildMarkers(){


    return Stack(

      children:
      widget.markers.map((marker){


        final x =
          marker.position.inMilliseconds /
          1000 *
          pixelsPerSecond;



        return Positioned(

          left:x,

          top:30,


          child: Column(

            children:[


              const Icon(
                Icons.flag,
                size:18,
                color:Colors.orange,
              ),


              Text(
                marker.name,

                style:
                const TextStyle(
                  color:Colors.white,
                  fontSize:10,
                ),
              )

            ],

          ),

        );


      }).toList(),

    );

  }
}