import 'package:flutter/material.dart';


class Waveform extends StatelessWidget {


  final List<double> samples;


  const Waveform({
    super.key,
    required this.samples,
  });



  @override
  Widget build(BuildContext context) {


    return CustomPaint(
      painter: WaveformPainter(samples),
    );

  }

}





class WaveformPainter
extends CustomPainter {


final List<double> samples;


WaveformPainter(
this.samples
);



@override
void paint(
Canvas canvas,
Size size
){


final paint =
Paint()
..color =
Colors.greenAccent
..strokeWidth=2;



final center =
size.height /2;



final step =
size.width /
samples.length;



for(
int i=0;
i<samples.length;
i++
){


final x =
i*step;


final amplitude =
samples[i] *
size.height /
2;



canvas.drawLine(

Offset(
x,
center-amplitude
),

Offset(
x,
center+amplitude
),

paint,

);


}



}



@override
bool shouldRepaint(
covariant CustomPainter old
){

return true;

}


}