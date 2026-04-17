# Phase 3 Implementation Roadmap

## 🚀 Phase 3 Features (Weeks 5–6)

### Feature 1: Biometric Auth (Two-Tier) ✅ Partially
**Status:** Tier 1 (local_auth) complete. Tier 2 (AWS Rekognition fallback) needs implementation.

#### Tier 1 — Native OS Biometric (COMPLETE)
- **Location:** `lib/services/biometric_service.dart`
- **Implementation:** 
  - Uses Flutter `local_auth` package
  - Supports Fingerprint and Face ID (native Android/iOS)
  - Detects available biometric types
  - Handles authentication with reason prompt

#### Tier 2 — Google Cloud Vision Fallback (TODO)
**Purpose:** When device has no biometric sensor or enrollment fails, fallback to camera-based liveness + profile matching.

**Required Components:**
1. **Google Cloud Vision Integration**
   - Add `google_mlkit_face_detection` package
   - Add `google_cloud_vision` package
   - Configure Google Cloud API key in `.env`
   - Implement face detection + liveness detection (blink/motion verification)

2. **Camera Capture Service**
   - Location: `lib/services/camera_liveness_service.dart`
   - Capture 3-frame sequence for liveness (blink detection)
   - Upload frames to AWS Rekognition

3. **Biometric Fallback Logic** (Update)
   - Location: `lib/services/biometric_service.dart` 
   - If local auth unavailable → try camera liveness
   - If liveness succeeds → compare with profile photo
   - Store fallback authentication result

**Code Template:**
```dart
// biometric_service.dart - Add this method
Future<BiometricResult> authenticateWithFallback({
  String reason = 'Confirm your identity',
}) async {
  // Try Tier 1: Native biometric
  final tier1Result = await authenticate(reason: reason);
  if (tier1Result.isSuccess) return tier1Result;
  
  // Fallback to Tier 2: Google Cloud Vision camera liveness
  try {
    final tier2Result = await _cameraLivenessService.performLivenessCheck();
    if (tier2Result.isSuccess) {
      return BiometricResult(
        isSuccess: true,
        usedFallback: true,
        method: 'google_cloud_vision_liveness',
      );
    }
  } catch (e) {
    developer.log('Google Cloud Vision fallback failed: $e');
  }
  
  return BiometricResult(isSuccess: false, error: 'Both auth methods failed');
}
```

---

### Feature 2: Resilient Background GPS ✅ Partially
**Status:** Basic background tracking complete. Protected Foreground Task refactor needed.

#### Current Implementation
- **Location:** `lib/services/shift_tracking_service.dart`
- **Features:**
  - Background position stream monitoring
  - Shift status tracking (active/paused/offline)
  - Heartbeat timer for GPS health

#### TODO: Protected Foreground Task Refactor
**Problem:** Xiaomi, OnePlus, and other OEMs kill background tasks aggressively.
**Solution:** Move GPS stream *inside* Android OS Protected Foreground Task.

**Required Components:**
1. **Add Foreground Service Configuration**
   - Add `flutter_foreground_task` dependency
   - Configure Android manifest for foreground service permissions
   - Create notification channel for shift tracking

2. **Update shift_tracking_service.dart**
   - Enable `enableWakeLock: true` in position stream
   - Wrap position updates in foreground task lifecycle
   - Implement watchdog for auto-restart on crash

**Code Template:**
```dart
// shift_tracking_service.dart - Add this import
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Add this method to initialize protected foreground task
Future<void> _initProtectedForegroundTask() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'shift_tracking_channel',
      channelName: 'Shift Tracking',
      channelDescription: 'Continuous GPS location tracking during shifts',
      onlyAlertOnce: true,
      showBadge: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      showBadge: true,
    ),
  );
}

// Modify position stream creation
void _startPositionStream() {
  _positionSubscription = Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
      timeLimit: const Duration(seconds: 30),
    ),
  ).listen(
    (Position position) {
      // Update GPS state while in protected foreground task
      _lastHeartbeatAt = DateTime.now();
      _lastAccuracy = position.accuracy;
      notifyListeners();
    },
    onError: (error) {
      developer.log('Position stream error: $error');
      _attemptWatchdogRestart();
    },
  );
}

// Add watchdog to restart on failure
Timer? _watchdogTimer;
void _startWatchdog() {
  _watchdogTimer = Timer.periodic(const Duration(seconds: 60), (_) {
    if (_positionSubscription == null || _status == ShiftStatus.offline) {
      developer.log('Watchdog: Position stream inactive, attempting restart');
      _attemptWatchdogRestart();
    }
  });
}

Future<void> _attemptWatchdogRestart() async {
  try {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await Future.delayed(const Duration(seconds: 2));
    _startPositionStream();
    developer.log('Watchdog: Position stream restarted successfully');
  } catch (e) {
    developer.log('Watchdog restart failed: $e');
    // Gracefully pause coverage if restart fails
    _status = ShiftStatus.paused;
    notifyListeners();
  }
}
```

---

### Feature 3: Location Degradation UX ✅ Needs Enhancement
**Status:** Partially implemented. Need "While Using App" mode with warning banner.

#### Current State
- Binary location permission handling (all-or-nothing)
- Hard requirement for "Always" permission to go online

#### TODO: Foreground-Only Mode
**New Behavior:**
- Worker can select "Use Location While Using App" → allows foreground-only tracking
- Shows amber warning banner on dashboard: "Coverage active while app is open. Open app during shifts."
- Shift protection remains active for foreground session
- Claims still process normally during foreground coverage window

**Required Changes:**

1. **Update Location Permission Service**
   - Location: `lib/services/location_permission_service.dart`
   - Add permission levels: `always`, `whenInUse`, `denied`

2. **Dashboard Enhancement**
   - Location: `lib/features/dashboard/`
   - Add amber warning banner when in "whenInUse" mode
   - Show clear copy: "Location is needed while the app is open"

3. **Shift Online Logic**
   - Location: `lib/features/dashboard/` or `lib/blocs/`
   - Allow going online with "whenInUse" permission
   - Track only when app is foregrounded

**Code Template:**
```dart
// location_permission_service.dart - Add permission enum
enum LocationPermissionMode { always, whenInUse, denied }

// Add method to check foreground mode
Future<LocationPermissionMode> getLocationPermissionMode() async {
  final status = await Geolocator.checkPermission();
  if (status == LocationPermission.whileInUse) {
    return LocationPermissionMode.whenInUse;
  } else if (status == LocationPermission.always) {
    return LocationPermissionMode.always;
  }
  return LocationPermissionMode.denied;
}

// dashboard_screen.dart - Add warning banner
if (locationMode == LocationPermissionMode.whenInUse) {
  Container(
    color: Colors.amber.shade100,
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        const Icon(Icons.warning_amber, color: Colors.amber),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Location needed while app is open. Keep app open during shifts.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

// Modify "Go Online" button behavior
ElevatedButton(
  onPressed: () {
    if (locationMode == LocationPermissionMode.denied) {
      // Prompt for "Always" permission
      _requestLocationPermission();
    } else if (locationMode == LocationPermissionMode.whenInUse) {
      // Show dialog explaining foreground-only limitation
      _showForegroundModeDialog();
    }
    // Then proceed with going online
  },
  child: const Text('Go Online'),
)
```

---

## Implementation Priority

| Priority | Feature | Effort | Impact |
|----------|---------|--------|--------|
| HIGH | Google Cloud Vision Fallback | 1 week | Handles 10% of devices with no biometric |
| HIGH | Protected Foreground Task | 3 days | Fixes GPS drops on Xiaomi/OnePlus |
| MEDIUM | Location Degradation UX | 2 days | Improves UX for foreground-only workers |

---

## Testing Checklist

- [ ] **Biometric Tier 2 (Google Cloud Vision):** Test camera liveness on device without fingerprint sensor
- [ ] **Protected Foreground Task:** Test background GPS tracking across phone app restarts (Xiaomi MIUI test device)
- [ ] **Location Degradation:** Verify shift protection active while app in foreground, disabled when backgrounded

---

## Dependencies to Add

```yaml
# pubspec.yaml
flutter_foreground_task: ^4.0.0
google_mlkit_face_detection: ^0.10.0
google_cloud_vision: ^5.0.0
camera: ^0.10.0
image: ^4.0.0
```

```groovy
// android/build.gradle
minSdkVersion 24  // Required for foreground service and Google ML Kit

// android/app/build.gradle - already includes Google ML Kit via google_mlkit_face_detection
// For Cloud Vision API calls, configure in Google Cloud Console
```

```dart
// .env
GOOGLE_CLOUD_API_KEY=your-google-cloud-api-key
```

---

## Notes
- All Phase 3 features maintain backward compatibility with Phase 1 & 2
- Implement features incrementally; each can be deployed independently
- Update user-facing docs after each feature goes live
