import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


class MasterMixer {


  Future<String> mix(
    List<String> inputs,
  ) async {


    final cacheDir =
        await getApplicationCacheDirectory();


    final hash =
    inputs.join('|').hashCode;


    final output =
    File(
    '${cacheDir.path}/master_$hash.wav',
    );



    // Si ya existe usamos cache
    if(await output.exists()){

      return output.path;

    }



    String command = "";


    for(final input in inputs){

      command +=
          '-i "$input" ';

    }



    command +=
    '-filter_complex ';


    command +=
    '"amix=inputs=${inputs.length}:duration=longest:normalize=0" ';


    command +=
    '-ar 44100 ';


    command +=
    '-ac 2 ';


    command +=
    '"${output.path}"';



    debugPrint("FFMPEG COMMAND:");
    debugPrint(command);



    final session =
        await FFmpegKit.execute(
          command,
        );



    final rc =
        await session.getReturnCode();



    if(!rc!.isValueSuccess()){

      throw Exception(
        "Master mix failed: $rc",
      );

    }



    if(!await output.exists()){

      throw Exception(
        "Master file was not created",
      );

    }



    return output.path;

  }

}