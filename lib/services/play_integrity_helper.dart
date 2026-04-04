import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_play_integrity_wrapper/flutter_play_integrity_wrapper.dart';

/// Requests a Play Integrity token on Android. Returns null on other platforms or on error.
Future<String?> obtainPlayIntegrityToken({
  required String cloudProjectNumber,
  String? nonce,
}) async {
  if (kIsWeb) return null;
  if (!Platform.isAndroid) return null;
  if (cloudProjectNumber.isEmpty) return null;

  final wrapper = FlutterPlayIntegrityWrapper();
  try {
    return await wrapper.requestIntegrityToken(
      cloudProjectNumber: cloudProjectNumber,
      nonce: nonce,
    );
  } on PlayIntegrityException {
    return null;
  } catch (_) {
    return null;
  }
}
