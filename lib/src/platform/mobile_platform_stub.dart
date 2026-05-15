import 'package:flutter/foundation.dart';

bool get isRunningOnMobileDevice => false;

String get defaultHostedBackendUrl {
  const configuredUrl = String.fromEnvironment('AIMEMO_BACKEND_BASE_URL');
  if (configuredUrl.isNotEmpty) {
    return configuredUrl;
  }
  if (kReleaseMode) {
    return 'https://aimemo-backend.onrender.com';
  }
  return 'http://127.0.0.1:8787';
}
