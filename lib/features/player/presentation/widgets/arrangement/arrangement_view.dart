import 'package:flutter/material.dart';

import '../../../../../core/tracks/track_mapper.dart';
import '../../../../songs/domain/song_marker.dart';
import '../../../domain/track_player.dart';


class ArrangementView extends StatelessWidget {


  final List<TrackModel> tracks;
  final Duration duration;
  final Duration position;
  final double pixelsPerSecond;
  final ScrollController scrollController;


  const ArrangementView({
    super.key,
    required this.tracks,
    required this.duration,
    required this.position,
    required this.scrollController,
    this.pixelsPerSecond = 100,
  });



  @override
  Widget build(BuildContext context) {


    final timelineWidth =
        duration.inMilliseconds /
        1000 *
        pixelsPerSecond;



    return SizedBox(

      height:
          tracks.length * 80,


      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection:
            Axis.horizontal,


        child: SizedBox(

          width:
              timelineWidth + 200,


          child: Stack(

  children: [


    Column(

      mainAxisSize:
          MainAxisSize.min,

      children: [

        for(
          int i = 0;
          i < tracks.length;
          i++
        )

        _TrackRow(
          track: tracks[i],
          width: timelineWidth,
        ),

      ],

    ),



    Positioned(

      left:
        position.inMilliseconds /
        1000 *
        pixelsPerSecond,


      top:0,


      bottom:0,


      child: Container(

        width:2,

        color:
        Colors.red,


      ),

    ),


  ],

),

        ),

      ),

    );

  }

}




class _TrackRow extends StatelessWidget {


  final TrackModel track;
  final double width;



  const _TrackRow({

    required this.track,
    required this.width,

  });



  @override
  Widget build(BuildContext context) {


    return SizedBox(

      height:80,


      child: Row(

        children: [



          SizedBox(

            width:150,


            child: Container(

              padding:
                  const EdgeInsets.all(8),


              decoration:
                  BoxDecoration(

                    color:
                      track.style.color
                      .withOpacity(.15),

                    border:
                      Border(
                        right:
                        BorderSide(
                          color:
                          Colors.white12,
                        ),
                      ),

                  ),


              child: Row(

                children: [


                  Icon(
                    track.style.icon,
                    color:
                      track.style.color,
                  ),


                  const SizedBox(
                    width:8,
                  ),


                  Expanded(

                    child: Text(

                      track.name
                          .split('.')
                          .first,


                      overflow:
                        TextOverflow
                        .ellipsis,


                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize:12,
                      ),

                    ),

                  ),


                ],

              ),

            ),

          ),



          SizedBox(

            width:width,


            child: Container(

              decoration:
              BoxDecoration(

                border:
                Border(

                  bottom:
                  BorderSide(
                    color:
                    Colors.white12,
                  ),

                ),

              ),


              child: Stack(

                children: [



                  Positioned.fill(

                    child: CustomPaint(

                      painter:
                      _GridPainter(),

                    ),

                  ),



                  Positioned(

                    left:0,
                    top:20,


                    child: Container(

                      height:35,


                      width:
                      width,


                      decoration:
                      BoxDecoration(

                        color:
                        track.style.color
                            .withOpacity(.35),


                        borderRadius:
                        BorderRadius.circular(6),

                      ),

                    ),

                  ),



                ],

              ),

            ),

          ),


        ],

      ),

    );

  }

}





class _GridPainter extends CustomPainter {


  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {


    const step = 100.0;


    final paint =
    Paint()
      ..color =
      Colors.white12
      ..strokeWidth =
      1;



    for(
    double x=0;
    x<size.width;
    x+=step
    ){

      canvas.drawLine(

        Offset(x,0),

        Offset(
          x,
          size.height,
        ),

        paint,

      );

    }

  }



  @override
  bool shouldRepaint(
      CustomPainter oldDelegate,
      )
  => false;

}