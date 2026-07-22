import 'dart:io';
import 'package:path_provider/path_provider.dart';


class MasterWaveformService {


  Future<String> createMasterFile(
    List<String> tracks,
  ) async {


    final dir =
        await getApplicationCacheDirectory();


    final output =
        File(
          '${dir.path}/master.wav.cache',
        );


    /*
      Aquí irá el proceso de mezcla
      de todos los tracks
    */


    return output.path;

  }

}