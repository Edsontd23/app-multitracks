import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_waveform/just_waveform.dart';


class WaveformService {


  Future<List<double>> generate(
    String path,
  ) async {


    final audioFile = File(path);


    if (!await audioFile.exists()) {
      throw Exception(
        "Audio not found: $path",
      );
    }



    final cacheDir =
        await getApplicationCacheDirectory();



    final fileName =
        audioFile.uri.pathSegments.last
        .replaceAll(
          '.',
          '_',
        );



    final waveFile = File(
      '${cacheDir.path}/$fileName.wave',
    );



    debugPrint(
      "Wave cache:"
    );

    debugPrint(
      waveFile.path
    );



    if(!await waveFile.exists()) {


      final progress =
          JustWaveform.extract(
            audioInFile: audioFile,
            waveOutFile: waveFile,
          );


      await for(final value in progress){


        debugPrint(
          "Waveform progress: ${value.progress}"
        );


      }


    }



    if(!await waveFile.exists()){

      throw Exception(
        "Failed creating waveform"
      );

    }



    final waveform =
        await JustWaveform.parse(
          waveFile,
        );


    return _normalize(
      waveform.data,
    );

  }





  List<double> _normalize(
    List<int> data,
  ){

    if(data.isEmpty){
      return [];
    }


    final max =
        data
        .map((e)=>e.abs())
        .reduce(
          (a,b)=>a>b?a:b,
        );


    return data.map((e){

      return e.abs()/max;

    }).toList();

  }


}