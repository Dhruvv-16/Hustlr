import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'api_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'shift_tracking_notifier.dart';

// ─── Shift Status ─────────────────────────────────────────────────────────────
enum ShiftStatus { offline, active, paused }

// ─── FRS Signal ──────────────────────────────────────────────────────────────
class FrsSignal {
  final String flag;
  final int score;
  final DateTime timestamp;
  FrsSignal({required this.flag, required this.score, required this.timestamp});
}

// ─── ShiftTrackingService ─────────────────────────────────────────────────────
/// Orchestrates native Android tracking via flutter_background_geolocation,
/// heartbeat telemetry to backend, and anti-spoofing signal detection.
class ShiftTrackingService extends ChangeNotifier {
  static final ShiftTrackingService instance = ShiftTrackingService._internal();
  ShiftTrackingService._internal();

  ShiftStatus _status = ShiftStatus.offline;
  double _lastAccuracy = 0.0;
  DateTime? _lastHeartbeatAt;
  final List<FrsSignal> _frsSignals = [];
  bool _initialized = false;

  ShiftStatus get status => _status;
  double get lastAccuracy => _lastAccuracy;
  DateTime? get lastHeartbeatAt => _lastHeartbeatAt;
  List<FrsSignal> get frsSignals => List.unmodifiable(_frsSignals);

  /// GPS status for the dashboard dot:
  /// 'active', 'weak' (accuracy > 50m), 'paused'
  String get gpsStateLabel {
    if (_status == ShiftStatus.paused) return 'paused';
    if (_status == ShiftStatus.offline) return 'offline';
    if (_lastAccuracy > 50) return 'weak';
    return 'active';
  }

  // ─── PUBLIC API ────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Configure BEFORE starting
    await bg.BackgroundGeolocation.ready(bg.Config(
      // Core tracking
      desiredAccuracy:        bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter:         10.0,      // fire every 10m movement
      stopTimeout:            5,         // minutes before stop detection
      
      // CRITICAL: Foreground service keeps OS from killing
      enableHeadless:         true,
      startOnBoot:            false,
      stopOnTerminate:        false,
      foregroundService:      true,      // Android foreground service
      
      // CRITICAL: Wake lock prevents Xiaomi/OnePlus kill
      // CRITICAL: Wake lock prevents Xiaomi/OnePlus kill
      heartbeatInterval:      60,        // ping every 60s even if not moving
      
      // Notification (required for foreground service on Android)
      notification: bg.Notification(
        title:    '⚡ Hustlr Active',
        text:     'Zone protection running — shift active',
        color:    '#1B5E20',
        smallIcon: 'mipmap/ic_launcher',
        sticky:   true,        // cannot be dismissed
      ),

      // Location permission
      locationAuthorizationRequest: 'Always',
      backgroundPermissionRationale: bg.PermissionRationale(
        title:   'Allow background location for shift protection',
        message: 'Hustlr needs background location to detect when you\'re in your zone during disruptions. This ensures you receive your payout.',
        positiveAction: 'Allow Always',
        negativeAction: 'Cancel',
      ),

      // Battery optimization
      pausesLocationUpdatesAutomatically: false,
      activityRecognitionInterval:        5000,

      // Debug (turn off for production)
      debug:   false,
      logLevel: bg.Config.LOG_LEVEL_OFF,
    ));

    // Position listener — fires on every location update
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      _handleLocation(location);
    }, (bg.LocationError error) {
      if (kDebugMode) print('[GPS] Location error: ${error.code}');
    });

    // Heartbeat listener — fires every 60s even when stationary
    bg.BackgroundGeolocation.onHeartbeat((bg.HeartbeatEvent event) {
      if (kDebugMode) print('[GPS] Heartbeat — still tracking');
      if (event.location != null) {
        _handleLocation(event.location!);
      }
    });

    // Detect if tracking stopped unexpectedly
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      if (!event.enabled) {
        ShiftTrackingNotifier.instance.notifyLocationDisabled();
        if (_status == ShiftStatus.active) {
          _status = ShiftStatus.paused;
          notifyListeners();
          NotificationService.instance.addShiftPaused();
        }
      }
    });
  }

  Future<void> startShift(String zone) async {
    await _initialize();
    
    // Update notification text with zone
    await bg.BackgroundGeolocation.setConfig(bg.Config(
      notification: bg.Notification(
         title:    '⚡ Hustlr Active',
         text:     'Coverage is live in $zone',
         color:    '#1B5E20',
         smallIcon: 'mipmap/ic_launcher',
         sticky:   true,
      )
    ));

    final state = await bg.BackgroundGeolocation.start();
    if (kDebugMode) print('[GPS] Tracking started: ${state.trackingMode}');
    
    _status = ShiftStatus.active;
    notifyListeners();

    // Request current location immediately (don't wait for movement)
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        timeout:  30,
        persist:  true,
        samples:  3,
      );
      _handleLocation(location);
    } catch(e) {
       if (kDebugMode) print('[GPS] Start shift initial location failed: $e');
    }
  }

  Future<void> stopShift() async {
    await bg.BackgroundGeolocation.stop();
    if (kDebugMode) print('[GPS] Tracking stopped');
    _status = ShiftStatus.offline;
    _frsSignals.clear();
    notifyListeners();
  }

  void resumeShift() async {
    if (_status == ShiftStatus.paused) {
      _status = ShiftStatus.active;
      await bg.BackgroundGeolocation.start();
      notifyListeners();
    }
  }

  // ─── POSITION HANDLER + ANTI-SPOOFING ─────────────────────────────────────

  Future<void> _handleLocation(bg.Location location) async {
    final lat = location.coords.latitude;
    final lng = location.coords.longitude;
    final accuracy = location.coords.accuracy;

    _lastAccuracy = accuracy;
    _lastHeartbeatAt = DateTime.now();

    if (kDebugMode) print('[GPS] Position: $lat, $lng (accuracy: ${accuracy}m)');

    if (_status == ShiftStatus.paused) {
      _status = ShiftStatus.active;
      NotificationService.instance.addShiftResumed();
    }

    // Signal A — isMockLocation (manual check via bg flag)
    final isMock = location.mock;
    if (isMock) {
      _addFrsSignal('mock_location_detected', 100); // AUTO_REJECT tier
      NotificationService.instance.addFraudAlert();
      await stopShift();
      return;
    }

    // Signal C — GPS accuracy degradation
    final isLowConfidence = accuracy > 50;

    // Signal E — Speed anomaly (>25 m/s = 90 km/h on a delivery bike)
    final speed = location.coords.speed; // m/s
    if (speed > 25.0) {
      _addFrsSignal('impossible_speed_detected', 15);
    }

    notifyListeners();
    ShiftTrackingNotifier.instance.notify(lat, lng, accuracy);

    // Send heartbeat to backend
    await _sendHeartbeat(location, isMock, isLowConfidence);
  }

  // ─── HEARTBEAT ─────────────────────────────────────────────────────────────

  Future<void> _sendHeartbeat(bg.Location pos, bool isMock, bool lowConf) async {
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId == null) return;

      int? batteryLevel;
      if (pos.battery.level != null) {
         batteryLevel = (pos.battery.level! * 100).toInt();
      }

      await ApiService.instance.postShiftHeartbeat(
        workerId: userId,
        lat: pos.coords.latitude,
        lng: pos.coords.longitude,
        accuracy: pos.coords.accuracy,
        timestamp: pos.timestamp,
        isMockLocation: isMock,
        activityType: 'in_vehicle',
        batteryLevel: batteryLevel, // enriched by backend
        isLowConfidence: lowConf,
      );
    } catch (_) {
      // Fail silently
    }
  }

  // ─── FRS SIGNALS ───────────────────────────────────────────────────────────

  void _addFrsSignal(String flag, int score) {
    _frsSignals.add(FrsSignal(flag: flag, score: score, timestamp: DateTime.now()));
    if (kDebugMode) debugPrint('[FRS] +$score — $flag');
  }
}
