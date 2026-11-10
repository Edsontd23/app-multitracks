import 'package:flutter/material.dart';


class AudioClip {

  final String id;

  final String name;

  final Duration start;

  final Duration duration;

  final Color color;


  const AudioClip({

    required this.id,

    required this.name,

    required this.start,

    required this.duration,

    required this.color,

  });


}