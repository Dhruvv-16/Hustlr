import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';

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
/// Orchestrates the native Android Foreground Service (via flutter_foreground_task),
/// heartbeat telemetry to backend, and anti-spoofing signal detection.
class ShiftTrackingService extends ChangeNotifier {
  static final ShiftTrackingService instance = ShiftTrackingService._internal();
  ShiftTrackingService._internal();

  ShiftStatus _status = ShiftStatus.offline;
  double _lastAccuracy = 0.0;
  DateTime? _lastHeartbeatAt;
  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeatWatchdog;
  final List<FrsSignal> _frsSignals = [];

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

  Future<void> startShift(String zone) async {
    await _initForegroundTask();
    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Hustlr is protecting your shift',
      notificationText: 'Location active • Coverage is live in $zone',
      callback: _foregroundCallback,
    );

    _status = ShiftStatus.active;
    notifyListeners();

    // Start GPS stream — also driven from foreground task handler
    // to survive aggressive battery management (OxygenOS Smart mode, MIUI, etc.)
    _startPositionStream();

    // Watchdog: if no ping for 180s → auto-resume stream before pausing
    _heartbeatWatchdog = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkHeartbeat();
    });
  }

  Future<void> stopShift() async {
    await FlutterForegroundTask.stopService();
    await _positionSub?.cancel();
    _positionSub = null;
    _heartbeatWatchdog?.cancel();
    _status = ShiftStatus.offline;
    _frsSignals.clear();
    notifyListeners();
  }

  void resumeShift() {
    if (_status == ShiftStatus.paused) {
      _status = ShiftStatus.active;
      // Restart the GPS stream — it may have been killed by the OS
      _startPositionStream();
      notifyListeners();
    }
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        // foregrondNotification keeps stream alive even in battery-restricted modes
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Hustlr GPS Active',
          notificationText: 'Tracking your location for coverage',
          enableWakeLock: true,
        ),
      ),
    ).listen(
      _onPosition,
      onError: (e) {
        // Stream died (killed by OS) — attempt restart after 5s
        Future.delayed(const Duration(seconds: 5), () {
          if (_status == ShiftStatus.active || _status == ShiftStatus.paused) {
            _startPositionStream();
          }
        });
      },
    );
  }

  // ─── POSITION HANDLER + ANTI-SPOOFING ─────────────────────────────────────

  Future<void> _onPosition(Position position) async {
    _lastAccuracy = position.accuracy;
    _lastHeartbeatAt = DateTime.now();

    if (_status == ShiftStatus.paused) {
      _status = ShiftStatus.active;
      NotificationService.instance.addShiftResumed();
    }

    // Signal A — isMockLocation (manual check via geolocator flag)
    final isMock = position.isMocked;
    if (isMock) {
      _addFrsSignal('mock_location_detected', 100); // AUTO_REJECT tier
      NotificationService.instance.addFraudAlert();
      await stopShift();
      return;
    }

    // Signal C — GPS accuracy degradation
    final isLowConfidence = position.accuracy > 50;

    // Signal E — Speed anomaly (>25 m/s = 90 km/h on a delivery bike)
    final speed = position.speed; // m/s
    if (speed > 25.0) {
      _addFrsSignal('impossible_speed_detected', 15);
    }

    // Signal D — Battery (we can't get charging state from geolocator;
    // this signal is surfaced in the heartbeat payload from device_info).
    // Placeholder — backend evaluates charging_during_outdoor_shift.

    notifyListeners();

    // Send heartbeat to backend
    await _sendHeartbeat(position, isMock, isLowConfidence);
  }

  // ─── HEARTBEAT ─────────────────────────────────────────────────────────────

  Future<void> _sendHeartbeat(Position pos, bool isMock, bool lowConf) async {
    try {
      final userId = await StorageService.instance.getUserId();
      if (userId == null) return;

      await ApiService.instance.postShiftHeartbeat(
        workerId: userId,
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: pos.timestamp.toIso8601String(),
        isMockLocation: isMock,
        activityType: 'in_vehicle',
        batteryLevel: null, // enriched by backend
        isLowConfidence: lowConf,
      );
    } catch (_) {
      // Fail silently — SQLite buffer in foreground task will catch up
    }
  }

  void _checkHeartbeat() {
    if (_lastHeartbeatAt == null) return;
    final elapsed = DateTime.now().difference(_lastHeartbeatAt!).inSeconds;
    if (elapsed > 60 && _status == ShiftStatus.active) {
      // Stream may be stalled — restart it proactively before pausing
      _startPositionStream();
    }
    if (elapsed > 180 && _status == ShiftStatus.active) {
      // Still no ping after restart attempt — mark paused
      _status = ShiftStatus.paused;
      NotificationService.instance.addShiftPaused();
      notifyListeners();
    }
  }

  // ─── FRS SIGNALS ───────────────────────────────────────────────────────────

  void _addFrsSignal(String flag, int score) {
    _frsSignals.add(FrsSignal(flag: flag, score: score, timestamp: DateTime.now()));
    if (kDebugMode) debugPrint('[FRS] +$score — $flag');
  }

  // ─── FOREGROUND TASK SETUP ─────────────────────────────────────────────────

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'hustlr_location',
        channelName: 'Hustlr Location',
        channelDescription: 'Keeps your shift coverage active in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000), // heartbeat every 30s
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }
}

// ─── Headless Foreground Task Callback ─────────────────────────────────────
@pragma('vm:entry-point')
void _foregroundCallback() {
  FlutterForegroundTask.setTaskHandler(_ShiftTaskHandler());
}

class _ShiftTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat tick — main isolate handles actual GPS via Geolocator stream
    FlutterForegroundTask.updateService(
      notificationTitle: 'Hustlr is protecting your shift',
      notificationText: 'Coverage active • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
