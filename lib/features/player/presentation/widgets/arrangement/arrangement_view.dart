import 'package:flutter/material.dart';
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

    final width =
        duration.inMilliseconds / 1000 *
        pixelsPerSecond;


    return SizedBox(

      height: tracks.length * 80,

      child: SingleChildScrollView(

        controller: scrollController,

        scrollDirection: Axis.horizontal,

        child: SizedBox(

          width: width,

          child: Column(

            children: tracks.map(
              (track){

                return _TrackRow(
                  track: track,
                  pixelsPerSecond: pixelsPerSecond,
                );

              },
            ).toList(),

          ),

        ),

      ),

    );

  }

}



class _TrackRow extends StatelessWidget {

  final TrackModel track;
  final double pixelsPerSecond;


  const _TrackRow({
    required this.track,
    required this.pixelsPerSecond,
  });


  @override
  Widget build(BuildContext context){


    final clips = track.clips;


    return SizedBox(

      height:80,

      child: Stack(

        children:[


          Container(

            height:80,

            decoration: BoxDecoration(

              border: Border(
                bottom: BorderSide(
                  color: Colors.white12,
                ),
              ),

              color:Colors.black12,

            ),

          ),



          ...clips.map((clip){


            final left =
                clip.start.inMilliseconds /
                1000 *
                pixelsPerSecond;



            final width =
                clip.duration.inMilliseconds /
                1000 *
                pixelsPerSecond;



            return Positioned(

              left:left,

              width:width,

              top:10,

              bottom:10,


              child: Container(

                decoration:BoxDecoration(

                  color:Colors.blueGrey,

                  borderRadius:
                    BorderRadius.circular(6),

                ),

              ),

            );


          }),


        ],

      ),

    );


  }

}