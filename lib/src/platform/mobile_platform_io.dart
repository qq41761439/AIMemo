import 'dart:io';

import 'package:flutter/foundation.dart';

bool get isRunningOnMobileDevice => Platform.isAndroid || Platform.isIOS;

String get defaultHostedBackendUrl {
  if (kReleaseMode) {
    return 'https://aimemo-backend.onrender.com';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8787';
  }
  return 'http://127.0.0.1:8787';
}
