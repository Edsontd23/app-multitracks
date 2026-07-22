import 'package:flutter/material.dart';

class TimelineGridPainter extends CustomPainter {

final double pixelsPerSecond;


TimelineGridPainter({
required this.pixelsPerSecond
});


@override
void paint(
Canvas canvas,
Size size
){

final paint = Paint()
..color = Colors.white12
..strokeWidth = 1;



for(
double x=0;
x<size.width;
x+=pixelsPerSecond
){

canvas.drawLine(
Offset(x,0),
Offset(x,size.height),
paint
);

}


for(
double y=0;
y<size.height;
y+=30
){

canvas.drawLine(
Offset(0,y),
Offset(size.width,y),
paint
);

}

}


@override
bool shouldRepaint(
covariant TimelineGridPainter old
){

return old.pixelsPerSecond !=
pixelsPerSecond;

}

}