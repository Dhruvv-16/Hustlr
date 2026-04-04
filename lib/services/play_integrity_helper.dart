import 'dart:io';

import 'package:flutter/foundation.dart';

/// Requests a Play Integrity token on Android. Returns null on other platforms or on error.
Future<String?> obtainPlayIntegrityToken({
  required String cloudProjectNumber,
  String? nonce,
}) async {
  // Plugin removed due to compilation breakages under new Android SDK
  if (kIsWeb) return null;
  if (!Platform.isAndroid) return null;
  
  return "mock_play_integrity_token_for_hackathon";
}
