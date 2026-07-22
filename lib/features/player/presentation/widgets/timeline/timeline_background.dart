import 'package:flutter/material.dart';

class TimelineBackground extends StatelessWidget {
  const TimelineBackground({
    super.key,
    required this.child,
    this.height = 80,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xff181818),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: child,
    );
  }
}