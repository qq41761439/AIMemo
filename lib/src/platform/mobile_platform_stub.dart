import 'package:flutter/foundation.dart';

bool get isRunningOnMobileDevice => false;

String get defaultHostedBackendUrl {
  if (kReleaseMode) {
    return 'https://aimemo-backend.onrender.com';
  }
  return 'http://127.0.0.1:8787';
}
