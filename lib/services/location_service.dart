import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';

class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  final List<Position> _shiftPings = [];
  double _currentDepthScore = 0.0;
  double _currentLat = 0.0;
  double _currentLon = 0.0;
  bool _isTracking = false;
  String _currentZone = 'Unknown';
  StreamSubscription<Position>? _positionStreamSubscription;

  double get depthScore => _currentDepthScore;
  double get currentLat => _currentLat;
  double get currentLon => _currentLon;
  bool get isTracking => _isTracking;
  String get currentZone => _currentZone;

  /// Push a one-shot GPS fix into the service without starting full tracking.
  /// Used by the dashboard to show location immediately on mount.
  void updateFromGps(double lat, double lon) {
    _currentLat = lat;
    _currentLon = lon;
    notifyListeners();
  }

  // Zone centroids
  static const Map<String, Map<String, double>> ZONE_CENTROIDS = {
    'Adyar Dark Store Zone':        {'lat': 13.0067, 'lon': 80.2206},
    'Anna Nagar Dark Store Zone':   {'lat': 13.0850, 'lon': 80.2101},
    'T Nagar Dark Store Zone':      {'lat': 13.0418, 'lon': 80.2341},
    'Velachery Dark Store Zone':    {'lat': 12.9815, 'lon': 80.2180},
    'OMR Dark Store Zone':          {'lat': 12.9165, 'lon': 80.2275},
    'Tambaram Dark Store Zone':     {'lat': 12.9249, 'lon': 80.1000},
    'Porur Dark Store Zone':        {'lat': 13.0358, 'lon': 80.1566},
    'Sholinganallur Dark Store Zone':{'lat': 12.9010, 'lon': 80.2279},
    'Mylapore Dark Store Zone':     {'lat': 13.0368, 'lon': 80.2676},
    'Perambur Dark Store Zone':     {'lat': 13.1080, 'lon': 80.2480},
    'Koramangala Dark Store Zone':  {'lat': 12.9352, 'lon': 77.6245},
    'HSR Layout Dark Store Zone':   {'lat': 12.9081, 'lon': 77.6476},
    'Indiranagar Dark Store Zone':  {'lat': 12.9784, 'lon': 77.6408},
    'Andheri Dark Store Zone':      {'lat': 19.1136, 'lon': 72.8697},
    'Bandra Dark Store Zone':       {'lat': 19.0596, 'lon': 72.8295},
  };

  static const double ZONE_OUTER_RADIUS = 3.0;
  static const double ZONE_MIDDLE_RADIUS = 2.0;
  static const double ZONE_CORE_RADIUS = 1.0;

  Future<void> initialize() async {
    // No mandatory auto-start here.
  }

  Future<bool> _requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<void> startTracking(String zone) async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    _currentZone = zone;
    _shiftPings.clear();
    _currentDepthScore = 0.0;
    _isTracking = true;
    notifyListeners();

    // Fetch initial location immediately so UI doesn't show 0.0000
    try {
      Position initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLat = initialPos.latitude;
      _currentLon = initialPos.longitude;
      _shiftPings.add(initialPos);
      _recalculateDepthScore();
      notifyListeners();
    } catch (_) {}

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // lowered to 5 meters for testing
      ),
    ).listen((Position position) {
      if (_shiftPings.isNotEmpty) {
        final lastPing = _shiftPings.last;
        final distanceDelta = Geolocator.distanceBetween(
          lastPing.latitude,
          lastPing.longitude,
          position.latitude,
          position.longitude,
        );
        final timeDeltaSec = position.timestamp.difference(lastPing.timestamp).inSeconds.abs();
        
        // Fraud Check: If distance > 100 meters AND speed > 20 m/s (72 km/h)
        if (timeDeltaSec > 0 && distanceDelta > 100) {
          final speed = distanceDelta / timeDeltaSec;
          if (speed > 20.0) {
            NotificationService.instance.addFraudAlert();
            stopTracking();
            return;
          }
        }
      }

      _currentLat = position.latitude;
      _currentLon = position.longitude;
      _shiftPings.add(position);

      final cutoff = DateTime.now().subtract(const Duration(hours: 8));
      _shiftPings.removeWhere((p) => p.timestamp.isBefore(cutoff));

      _recalculateDepthScore();
      notifyListeners();
    });
  }

  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  void _recalculateDepthScore() {
    if (_shiftPings.isEmpty || _currentZone == 'Unknown') return;
    final centroid = ZONE_CENTROIDS[_currentZone];
    if (centroid == null) return;

    double totalScore = 0.0;
    for (final ping in _shiftPings) {
      final distKm = _haversineKm(
        ping.latitude, ping.longitude,
        centroid['lat']!, centroid['lon']!,
      );

      double pingScore;
      if (distKm <= ZONE_CORE_RADIUS) {
        pingScore = 0.8 + (1.0 - distKm / ZONE_CORE_RADIUS) * 
        .2;
      } else if (distKm <= ZONE_MIDDLE_RADIUS) {
        pingScore = 0.4 + (1.0 - (distKm - ZONE_CORE_RADIUS) /
        
            (ZONE_MIDDLE_RADIUS - ZONE_CORE_RADIUS)) * 0.4;
      } else if (distKm <= ZONE_OUTER_RADIUS) {
        pingScore = (1.0 - (distKm - ZONE_MIDDLE_RADIUS) /
            (ZONE_OUTER_RADIUS - ZONE_MIDDLE_RADIUS)) * 0.4;
      } else {
        pingScore = 0.0;
      }
      totalScore += pingScore;
    }

    _currentDepthScore = totalScore / _shiftPings.length;
    _currentDepthScore = _currentDepthScore.clamp(0.0, 1.0);
  }

  double getDepthMultiplier() {
    if (_currentDepthScore <= 0.20) return 0.0;
    if (_currentDepthScore <= 0.40) return 0.3;
    if (_currentDepthScore <= 0.60) return 0.6;
    if (_currentDepthScore <= 0.80) return 0.85;
    return 1.0;
  }

  double calculateFinalPayout(double grossPayout) {
    return (grossPayout * getDepthMultiplier()).roundToDouble();
  }

  double getGpsJitterVariance() {
    if (_shiftPings.length < 3) return 0.0;
    final recent = _shiftPings.take(10).toList();
    final lats = recent.map((p) => p.latitude).toList();
    final mean = lats.reduce((a, b) => a + b) / lats.length;
    final variance = lats
        .map((l) => (l - mean) * (l - mean))
        .reduce((a, b) => a + b) / lats.length;
    return variance;
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  Map<String, dynamic> getClaimSensorData() {
    return {
      'gps_lat':           _currentLat,
      'gps_lon':           _currentLon,
      'gps_jitter':        getGpsJitterVariance(),
      'depth_score':       _currentDepthScore,
      'depth_multiplier':  getDepthMultiplier(),
      'ping_count':        _shiftPings.length,
      'zone':              _currentZone,
      'is_tracking':       _isTracking,
    };
  }
}
