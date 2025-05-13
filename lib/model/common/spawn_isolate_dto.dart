import 'dart:isolate';
import 'dart:ui';

import 'package:coconut_lib/coconut_lib.dart';

class SpawnIsolateDto {
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;
  final dynamic handler;
  final NetworkType networkType;

  SpawnIsolateDto(this.sendPort, this.rootIsolateToken, this.handler, this.networkType);
}
