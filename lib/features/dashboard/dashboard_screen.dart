import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/location_service.dart';
import '../../services/mock_data_service.dart';

import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/router/app_router.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/shift_status_dot.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/pdf_generator.dart';
import '../../models/policy.dart';

import '../../features/shared/widgets/battery_optimization_prompt.dart';
import '../../services/shift_tracking_service.dart';
import '../../services/fraud_sensor_service.dart';

import '../../services/dynamic_translator.dart';
import '../../services/app_events.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Map<String, dynamic>? policyData;
  Map<String, dynamic>? walletData;
  Map<String, dynamic>? disruptionData;
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? nudgeData;
  Map<String, dynamic>? workAdvisorData;
  Map<String, dynamic>? activeDisruption;
  String? userId;
  String? userZone;
  String? userName;
  bool isLoading = true;
  bool _isGoingOnline =
      false; // separate flag so Go Online never blanks the whole dashboard
  Timer? _disruptionRefreshTimer;
  StreamSubscription<Position>? _locationStream;

  // Stream subscriptions
  StreamSubscription? _policySub;
  StreamSubscription? _walletSub;
  StreamSubscription? _claimSub;

  // Guard: prevents concurrent _loadDashboardData calls
  bool _isDashboardLoading = false;

  // Debounce timestamps for event-driven reloads
  int _lastWalletReload = 0;
  int _lastClaimReload = 0;

  int? liveIssScore;
  double? liveDynamicPrice;

  // Liveness HUD
  final List<StatusEvent> _events = [];
  StreamSubscription<StatusEvent>? _eventSub;
  late AnimationController _radarController;

  // Debug variables
  bool _debugMode = false;
  bool _enableLiveML = false;
  String _locationPermissionStatus = 'unknown';
  bool _backgroundTrackingActive = false;

  // Live pulled from LocationService.instance on every GPS tick
  double get _lastLat => LocationService.instance.currentLat;
  double get _lastLng => LocationService.instance.currentLon;
  double get _zoneDepthScore => LocationService.instance.depthScore * 100;

  // API health check results
  Map<String, String> _apiHealthStatus = {};
  bool _reverifyPromptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _fetchInitialLocation(); // ← get GPS fix immediately without waiting for movement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
    });

    // Subscribe to LocationService so debug values refresh on every GPS ping
    LocationService.instance.addListener(_onLocationUpdate);
    ShiftTrackingService.instance.addListener(_onShiftUpdate);

    _loadDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRunRiskIdentityReview();
    });
    _disruptionRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (!mounted) return;
      _loadDashboardData();
    });

    _policySub = AppEvents.instance.onPolicyUpdated.listen((_) async {
      await _loadDashboardData();
      if (policyData != null) {
        final premiumRaw = policyData!['weekly_premium'];
        final premium = (premiumRaw is num)
            ? premiumRaw.toDouble()
            : double.tryParse(premiumRaw.toString()) ?? 49.0;
        NotificationService.instance.addPremiumDeducted(premium.round());
      }
    });
    // Debounced: only reload wallet/claim data at most once every 5 seconds
    _walletSub = AppEvents.instance.onWalletUpdated.listen((_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastWalletReload > 5000) {
        _lastWalletReload = now;
        _loadDashboardData();
      }
    });
    _claimSub = AppEvents.instance.onClaimUpdated.listen((_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastClaimReload > 5000) {
        _lastClaimReload = now;
        _loadDashboardData();
      }
    });

    AppEvents.instance.onProfileUpdated.listen((_) {
      if (mounted) _loadDashboardData();
    });

    // Liveness HUD subscription
    _eventSub = LocationService.instance.eventLog.listen((event) {
      if (mounted) {
        setState(() {
          _events.insert(0, event);
          if (_events.length > 50) _events.removeLast();
        });
      }
    });

    // Initialize Radar Animation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  /// Get a one-shot GPS fix immediately on mount so the debug panel shows
  /// real coordinates without requiring the user to physically move first.
  Future<void> _fetchInitialLocation() async {
    try {
      if (kIsWeb) {
        var p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
        }
        if (p == LocationPermission.denied ||
            p == LocationPermission.deniedForever) {
          return;
        }
      } else {
        final hasPermission = await Permission.locationWhenInUse.isGranted;
        if (!hasPermission) return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      LocationService.instance.updateFromGps(pos.latitude, pos.longitude);
      if (mounted) setState(() {});
    } catch (_) {
      // Silently skip if GPS unavailable
    }
  }

  /// Run a live health check against each key API endpoint and store results.
  bool _isMLFetching = false;
  Future<void> _fetchLiveMLData(String tier) async {
    if (!mounted || !_enableLiveML) return;
    setState(() => _isMLFetching = true);
    try {
      final issData = await ApiService.instance.getIssScore();
      if (!mounted) return;
      final score = issData['iss_score'] as int?;
      if (score != null) {
        liveIssScore = score;
        final premData =
            await ApiService.instance.getDynamicPremium(tier, score);
        if (mounted) {
          setState(() {
            liveDynamicPrice = (premData['final_premium'] as num?)?.toDouble();
            _isMLFetching = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isMLFetching = false);
    }
  }

  void _checkApiHealth() async {
    setState(() => _apiHealthStatus = {'_loading': 'true'});
    final base = ApiService.baseUrl;
    final results = <String, String>{};

    Future<String> ping(String path) async {
      try {
        final res = await http
            .get(
              Uri.parse('$base$path'),
            )
            .timeout(const Duration(seconds: 8));
        return res.statusCode < 400
            ? '✅ ${res.statusCode}'
            : '❌ ${res.statusCode}';
      } on TimeoutException {
        return '⏱ TIMEOUT';
      } catch (e) {
        return '❌ ERR';
      }
    }

    results['GET /health'] = await ping('/health');
    if (userId != null) {
      results['GET /workers/:id'] = await ping('/workers/$userId');
      results['GET /policies/:id'] = await ping('/policies/$userId');
      results['GET /wallet/:id'] = await ping('/wallet/$userId');
      results['GET /claims/:id'] = await ping('/claims/$userId');
      final zone = Uri.encodeComponent(userZone ?? '');
      results['GET /disruptions'] = await ping('/disruptions/$zone');
    } else {
      results['NOTE'] = 'Log in first for user-scoped endpoints';
    }

    if (mounted) setState(() => _apiHealthStatus = results);
  }

  Future<void> _checkLocationPermission() async {
    // Skip permission checks on web - permission_handler not supported
    if (kIsWeb) {
      setState(() {
        _locationPermissionStatus = 'GRANTED';
        _backgroundTrackingActive = false;
      });
      return;
    }

    final status = await Permission.locationWhenInUse.status;
    final bgStatus = await Permission.locationAlways.status;
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();

    if (mounted) {
      setState(() {
        if (!gpsEnabled) {
          _locationPermissionStatus = 'GPS_DISABLED_ON_DEVICE';
        } else {
          _locationPermissionStatus = status.toString();
        }
        _backgroundTrackingActive = bgStatus.isGranted && gpsEnabled;
      });
    }
  }

  Future<void> _maybeRunRiskIdentityReview() async {
    if (!mounted || _reverifyPromptOpen) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastRiskReview = StorageService.getInt('lastRiskReviewAt') ?? 0;
    const minGapMs = 15 * 60 * 1000; // do not recheck too frequently
    if (now - lastRiskReview < minGapMs) return;
    // Note: write the timestamp only after we decide to actually challenge,
    // so an early unmount doesn't consume the 15-min window.

    final hasEnrollment =
        await StorageService.instance.isIdentityEnrollmentComplete();
    if (!mounted) return; // guard: widget may unmount during storage read
    bool shouldChallenge = !hasEnrollment;
    bool isRiskTriggered = false;

    if (!shouldChallenge) {
      try {
        final sensor = await FraudSensorService.collectPayload();
        if (!mounted) return; // guard: GPS sampling takes 1–2 seconds
        final ml = await ApiService.instance.validateFraudTelemetry(sensor);
        if (!mounted) return; // guard: network call
        final anomalous = ml['is_anomalous'] == true;
        final fps = (ml['fps_score'] as num?)?.toDouble() ?? 0.0;
        isRiskTriggered = anomalous || fps >= 0.75;
      } catch (_) {
        isRiskTriggered = false;
      }
      final randomAudit = math.Random().nextInt(100) < 3; // 3% random checks
      shouldChallenge = isRiskTriggered || randomAudit;
    }

    if (!shouldChallenge || !mounted) return;

    // Commit the review timestamp only now that we are actually challenging
    await StorageService.setLastRiskReviewAt(now);
    if (!mounted) return;

    _reverifyPromptOpen = true;
    final reason = Uri.encodeComponent(
      !hasEnrollment
          ? 'Complete first-time identity enrollment to secure your account.'
          : (isRiskTriggered
              ? 'Suspicious account activity detected. Re-verify your identity to continue.'
              : 'Quick security check: please re-verify your identity.'),
    );
    final requireTwoTier = !hasEnrollment;
    // Use the global appRouter instead of context.push — avoids stale context
    // crash when the widget tree switches (e.g. shift going active mid-await)
    final result = await appRouter.push<Map<String, dynamic>>(
      '${AppRoutes.stepUpAuth}?reason=$reason&requireTwoTier=$requireTwoTier',
    );
    _reverifyPromptOpen = false;

    if (!mounted) return;
    if (result != null && result['verified'] == true) {
      await StorageService.instance.markIdentityVerifiedNow();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identity verification was not completed.'),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAllPermissions();
      _checkLocationPermission();
      // Re-fetch data in case user just granted permissions (location etc.)
      // or the app was backgrounded while data was loading.
      if (!_isDashboardLoading) {
        _loadDashboardData();
      }
    }
  }

  Future<void> _recheckAllPermissions() async {
    final locationPerm = await Geolocator.checkPermission();

    if (mounted) {
      setState(() {
        _backgroundTrackingActive = locationPerm == LocationPermission.always;
        _locationPermissionStatus = locationPerm.toString();
      });
    }
  }

  int _lastLocUpdate = 0;
  void _onLocationUpdate() {
    if (!mounted) return;
    
    final newZone = LocationService.instance.currentZone;
    if (newZone != "Unknown Zone" && newZone != "Outside Service Area" && newZone != userZone) {
      final zoneShort = newZone.split(' ').first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Location Verified: Entering $zoneShort Hub'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      setState(() {
        userZone = newZone;
      });
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLocUpdate > 5000) {
      // Every 5 seconds max
      _lastLocUpdate = now;
      setState(() {});
    }
  }

  int _lastShiftUpdate = 0;
  void _onShiftUpdate() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastShiftUpdate > 5000) {
      // Every 5 seconds max
      _lastShiftUpdate = now;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _eventSub?.cancel();
    LocationService.instance.removeListener(_onLocationUpdate);
    ShiftTrackingService.instance.removeListener(_onShiftUpdate);
    WidgetsBinding.instance.removeObserver(this);
    _disruptionRefreshTimer?.cancel();
    _locationStream?.cancel();
    _policySub?.cancel();
    _walletSub?.cancel();
    _claimSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    // Prevent concurrent API call stacks from piling up
    if (_isDashboardLoading) return;
    _isDashboardLoading = true;
    userId = await StorageService.instance.getUserId();
    userZone = await StorageService.instance.getUserZone();
    userName = await StorageService.instance.getUserName();

    // ── Demo Consistency Guard ───────────────────────────────────────────
    final mockSvc = Provider.of<MockDataService>(context, listen: false);
    if (mockSvc.worker.id.isNotEmpty) {
      if (mounted) {
        setState(() {
          userId = mockSvc.worker.id;
          userName = mockSvc.worker.name;
          userZone = mockSvc.worker.zone;
          
          policyData = mockSvc.hasActivePolicy ? {
            'id': 'PROTO-POL-${mockSvc.worker.id.hashCode}',
            'plan_tier': mockSvc.activePolicy.plan.split(' ')[0].toLowerCase(),
            'plan_name': mockSvc.activePolicy.plan,
            'status': mockSvc.activePolicy.status,
            'weekly_premium': mockSvc.activePolicy.premium,
            'coverage_start': mockSvc.activePolicy.coverageStart,
            'commitment_end': mockSvc.activePolicy.coverageEnd,
          } : null;
          
          walletData = {
            'balance': mockSvc.walletBalance,
            'total_payouts': mockSvc.monthlySavings,
            'total_premiums': mockSvc.totalPremiums,
            'transactions': mockSvc.transactions,
          };

          if (mockSvc.activeDisruption != null) {
            final active = mockSvc.activeDisruption!;
            activeDisruption = {
              'display_name': active.triggerName,
              'trigger_type': active.triggerIcon,
            };
            disruptionData = {
              'active': true,
              'trigger_type': active.triggerName,
              'zone': userZone,
            };
          } else {
            activeDisruption = null;
            disruptionData = const {'active': false};
          }

          weatherData = {
            'source': 'Mock Engine',
            'rainfall_mm_1h': mockSvc.activeDisruption?.triggerIcon == 'rain' ? 72.4 : 0.0,
            'temp_celsius': mockSvc.activeDisruption?.triggerIcon == 'heat' ? 42.0 : 29.0,
          };

          liveIssScore = mockSvc.worker.issScore;
          isLoading = false;
        });
      }
      _isDashboardLoading = false;
      return;
    }

    if (userId == null) {
      _isDashboardLoading = false;
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final policyRes = await ApiService.instance.getPolicy(userId!);
      final walletRes = await ApiService.instance.getWallet(userId!);
      Map<String, dynamic> disruptionRes = {};
      try {
        final w = await ApiService.instance.getWorkerById(userId!);
        final rawIss = w['iss_score'];
        if (rawIss is num && mounted) {
          setState(() => liveIssScore = rawIss.round().clamp(0, 100));
        }
        disruptionRes = await ApiService.instance.getDisruptions(
          userZone ?? '',
        );
      } catch (_) {}

      final rawPolicy = policyRes['policy'] as Map<String, dynamic>?;
      final tier = rawPolicy?['plan_tier'] as String?;

      // Support new schema field names: coverage_start / commitment_end
      final policyWithAliases = rawPolicy == null ? null : {
        ...rawPolicy,
        // Ensure start_date / end_date are always populated for legacy code paths
        if (!rawPolicy.containsKey('start_date'))
          'start_date': rawPolicy['coverage_start'],
        if (!rawPolicy.containsKey('end_date'))
          'end_date': rawPolicy['commitment_end'] ?? rawPolicy['paid_until'],
        'plan_name': _planDisplayName(tier),
      };

      // Gate: only show policyData if status is active or renewed
      final rawStatus = rawPolicy?['status']?.toString().toLowerCase() ?? '';
      final isPolicyActive = rawStatus == 'active' || rawStatus == 'renewed';
      policyData = isPolicyActive ? policyWithAliases : null;

      final events = disruptionRes['disruptions'] as List<dynamic>? ?? [];
      final active = disruptionRes['active'] == true;
      final rawWeather = disruptionRes['weather'] as Map<String, dynamic>?;
      final rawNudge =
          disruptionRes['predictive_nudge'] as Map<String, dynamic>?;
      final rawAdvisor = disruptionRes['work_advisor'] as Map<String, dynamic>?;

      Map<String, dynamic>? latestDisruption;
      if (!active || events.isEmpty) {
        disruptionData = const {'active': false};
      } else {
        latestDisruption = events.first as Map<String, dynamic>;
        disruptionData = {
          'active': true,
          'trigger_type': latestDisruption['display_name'] as String? ??
              _disruptionTriggerLabel(
                  latestDisruption['trigger_type'] as String?),
          'zone': userZone ?? 'Your Zone',
        };
      }

      // The dashboard data has landed! Render it instantly.
      if (mounted) {
        setState(() {
          walletData = walletRes;
          weatherData = rawWeather;
          activeDisruption = latestDisruption;
          nudgeData = rawNudge;
          workAdvisorData = rawAdvisor;
          isLoading = false;
        });
      }

      // ── Organic ML Data Fetch (Detached Background Task) ──
      // This prevents the app from freezing if Render is experiencing a cold start.
      _fetchLiveMLData(tier ?? 'standard');

      // Trigger notifications based on policy status and disruptions
      final hasActivePolicy = policyData != null;
      final hasDisruptions = events.isNotEmpty;

      // Only fire notifications for genuinely new data — not every load
      // Rain alert: only when disruption is truly active (server-confirmed)
      if (hasDisruptions && active && hasActivePolicy) {
        NotificationService.instance.addRainAlert(userZone ?? 'your zone');
      }
      // Missed payout: only for users WITHOUT a policy AND confirmed disruptions
      if (hasDisruptions && active && !hasActivePolicy) {
        NotificationService.instance.addMissedPayout(350);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    } finally {
      _isDashboardLoading = false;
    }
  }

  static String _planDisplayName(String? tier) {
    const m = {
      'basic': 'Basic Shield',
      'standard': 'Standard Shield',
      'full': 'Full Shield',
    };
    return m[tier] ?? 'Standard Shield';
  }

  static String _disruptionTriggerLabel(String? t) {
    const labels = {
      'rain_heavy': 'Heavy Rain',
      'platform_outage': 'Platform Downtime',
      'heat_severe': 'Extreme Heat',
      'extreme_heat': 'Extreme Heat',
      'bandh': 'Bandh / Curfew',
      'aqi_severe': 'Severe Pollution',
      'aqi_hazardous': 'Severe Pollution',
    };
    if (t == null) return 'Rain';
    return labels[t] ??
        (t.isNotEmpty
            ? '${t[0].toUpperCase()}${t.substring(1).replaceAll('_', ' ')}'
            : 'Rain');
  }

  String _getGreetingText(BuildContext context) {
    final h = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    if (h < 12) return l10n.dashboard_greeting_morning;
    if (h < 17) return l10n.dashboard_greeting_afternoon;
    return l10n.dashboard_greeting_evening;
  }

  void _handleNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        context.go('/policy');
        break;
      case 2:
        context.go('/claims');
        break;
      case 3:
        context.go('/wallet');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
            child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        )),
      );
    }

    final isLocationDenied =
        _locationPermissionStatus.contains('permanentlyDenied');
    final isGpsOff = _locationPermissionStatus == 'GPS_DISABLED_ON_DEVICE';

    final rawPlanName = policyData?['plan_name'] ?? 'Standard Shield';
    final List<dynamic>? ridersData = policyData?['riders'];
    String planName = rawPlanName;
    if (ridersData != null && ridersData.isNotEmpty) {
      final names = ridersData.map((r) => r['name'].toString()).join(' + ');
      planName = '$rawPlanName + $names';
    }

    String titleCase(String text) {
      if (text.isEmpty) return text;
      return text.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    final displayUserName = titleCase(userName ?? 'Karthik');

    // Total premium: use the canonical tier price (from Policy model), NOT raw DB value
    // This ensures ₹60 stale DB entries show as ₹49 for standard, etc.
    final String premium = liveDynamicPrice != null
        ? liveDynamicPrice!.toStringAsFixed(0)
        : PlanTierPrice.fromString(
            policyData?['plan_tier']?.toString() ?? 'standard',
          ).weeklyPremium.toString();

    // Derive missed-payout amount from shadow_policies nudge data (real DB field),
    // then fall back to a disruption-based estimate — never reads a non-existent field.
    final shadowPayout = (nudgeData?['simulated_payout'] as num?)?.toInt()
        ?? (nudgeData?['missed_amount'] as num?)?.toInt();
    final disruptionCount = ((nudgeData?['disruption_count'] as num?)?.toInt() ?? 0);
    final pAmount = shadowPayout ?? (disruptionCount > 0 ? disruptionCount * 120 : 350);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF161B22),
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, displayUserName),
                        const SizedBox(height: 16),
                        _buildSystemStatusFeed(),
                        const SizedBox(height: 16),
                        _buildLiveStatsRow(),
                        const SizedBox(height: 24),
                        _buildTitleSection(l10n, displayUserName),
                        const SizedBox(height: 20),
                        if (isLocationDenied || isGpsOff) ...[
                          _buildLocationStatusBanner(context,
                              isGpsOff: isGpsOff),
                          const SizedBox(height: 16),
                        ],
                        if (nudgeData != null) ...[
                          _buildPredictiveNudgeCard(l10n),
                          const SizedBox(height: 16),
                        ],
                        _buildRainAlertCard(l10n),
                        if (workAdvisorData != null) ...[
                          const SizedBox(height: 16),
                          _buildWorkAdvisorCard(),
                        ],
                        const SizedBox(height: 20),
                        _buildActivePolicyCard(
                            planName, premium, l10n, ridersData),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111311)
                                : const Color(0xFFF0F4F0),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            children: [
                              _buildActionCards(context, l10n),
                              // Show missed-payouts card only for UNINSURED users
                              // so it serves as a conversion nudge, not a bug.
                              if (policyData == null) ...[
                                const SizedBox(height: 16),
                                _buildMissedPayoutsCard(pAmount, context, l10n),
                              ],
                            ],
                          ),
                        ),
                        if (_debugMode) _buildDebugPanel(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayUserName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1c1f1c) : const Color(0xFFE8F5E9);
    final borderColor = isDark
        ? const Color(0xFF3fff8b).withOpacity(0.1)
        : const Color(0xFF1B5E20).withOpacity(0.2);
    final iconColor = isDark
        ? const Color(0xFFe1e3de).withOpacity(0.8)
        : const Color(0xFF1B5E20);
    final mintColor =
        isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: mintColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: mintColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person, color: mintColor, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          displayUserName, // passed in
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            if (ShiftTrackingService.instance.status == ShiftStatus.active)
              AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return Container(
                    width: 32 * _radarController.value,
                    height: 32 * _radarController.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: mintColor.withOpacity(1.0 - _radarController.value),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            const ShiftStatusDot(),
          ],
        ),
        const Spacer(),
        _buildMintIconBtn(Icons.headset_mic_rounded,
            () => context.push(AppRoutes.support), mintColor, isDark),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
            color: _debugMode ? Colors.red : Colors.grey,
          ),
          onPressed: () => setState(() => _debugMode = !_debugMode),
        ),
        const SizedBox(width: 8),
        _buildMintIconBtn(Icons.notifications_rounded,
            () => context.push(AppRoutes.notifications), mintColor, isDark),
      ],
    );
  }

  Widget _buildMintIconBtn(
      IconData icon, VoidCallback onTap, Color mintColor, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: mintColor.withOpacity(0.15)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: mintColor, size: 18),
      ),
    );
  }

  Widget _buildTitleSection(AppLocalizations l10n, String displayUserName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mintColor =
        isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final deepContainer =
        isDark ? const Color(0xFF003324) : const Color(0xFFE8F5E9);
    final subtextColor =
        isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.nav_home,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: deepContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: mintColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    DynamicTranslator.of(context)
                            .translateSync(userZone ?? 'BENGALURU, KA')
                        .toUpperCase(),
                    style: TextStyle(
                      color: mintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Manrope',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_getGreetingText(context)}, $displayUserName', // passed in
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Widget _buildActivePolicyCard(String planName, String premium,
      AppLocalizations l10n, List<dynamic>? riders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor =
        isDark ? const Color(0xFF10B981) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleText =
        isDark ? const Color(0xFFe1e3de) : const Color(0xFF4A6741);
    final shadowColor = isDark
        ? const Color(0xFF1B5E20).withOpacity(0.04)
        : const Color(0xFF1B5E20).withOpacity(0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isMLFetching
                    ? 'CALCULATING AI PREMIUM...'
                    : (liveDynamicPrice != null
                        ? 'ML ADJUSTED PREMIUM'
                        : 'YOUR WEEKLY PREMIUM'),
                style: TextStyle(
                  color: _isMLFetching
                      ? Colors.orangeAccent
                      : (liveDynamicPrice != null
                          ? Colors.amberAccent
                          : subtleText),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (_isMLFetching)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0, bottom: 4.0),
                      child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.orangeAccent)),
                    )
                  else
                    Text(
                      '₹$premium',
                      style: TextStyle(
                        color: liveDynamicPrice != null
                            ? Colors.amberAccent
                            : mintColor,
                        fontSize: liveDynamicPrice != null ? 30 : 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  if (!_isMLFetching)
                    Text(
                      liveDynamicPrice != null ? ' (ML Adjusted)' : '/ week',
                      style: TextStyle(
                        color: liveDynamicPrice != null
                            ? Colors.amberAccent
                            : subtleText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Manrope',
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            planName.replaceAll(' ', '\n'),
            style: TextStyle(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCoverageChip(l10n.claims_heavy_rain.toUpperCase(),
                  Icons.water_drop_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_extreme_heat.toUpperCase(),
                  Icons.wb_sunny_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_platform_downtime.toUpperCase(),
                  Icons.security_rounded, mintColor, isDark),
              if (riders != null)
                ...riders.map((r) {
                  final name = r['name']?.toString() ?? '';
                  IconData icon = Icons.security_rounded;
                  if (name.contains('Cyclone')) icon = Icons.cyclone_rounded;
                  if (name.contains('Curfew')) icon = Icons.groups_rounded;
                  if (name.contains('Election')) {
                    icon = Icons.how_to_vote_rounded;
                  }
                  if (name.contains('App Downtime')) {
                    icon = Icons.phonelink_off_rounded;
                  }

                  return _buildCoverageChip(
                      name.replaceAll(' Rider', '').toUpperCase(),
                      icon,
                      mintColor,
                      isDark);
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageChip(
      String label, IconData icon, Color mintColor, bool isDark) {
    final chipBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: mintColor, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: mintColor,
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  /// Earning-stability + shift hints from ML `/work-advisor` (bundled in disruptions API).
  Widget _buildWorkAdvisorCard() {
    final a = workAdvisorData;
    if (a == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF141614) : const Color(0xFFF8FAF8);
    final mintColor =
        isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = textColor.withOpacity(0.65);

    final t = DynamicTranslator.of(context);
    final esi = (a['earning_stability_index'] as num?)?.round() ?? 0;
    final band = t.translateSync(
        a['stability_band_label'] as String? ?? 'Earning outlook');
    final headline = t.translateSync(a['headline'] as String? ?? '');
    final nudge = t.translateSync(a['coverage_nudge'] as String? ?? '');
    final suggest = a['suggest_activate_coverage'] == true;
    final windows = a['recommended_shift_windows'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mintColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: mintColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'WORK STABILITY',
                  style: TextStyle(
                    color: mintColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mintColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ESI $esi',
                  style: TextStyle(
                    color: mintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            band,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: TextStyle(
              color: subColor,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontFamily: 'Manrope',
            ),
          ),
          if (windows.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Suggested shift focus',
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 6),
            ...windows.take(2).map((w) {
              final m = w is Map<String, dynamic> ? w : null;
              if (m == null) return const SizedBox.shrink();
              final label = t.translateSync(m['label'] as String? ?? '');
              final hours = m['hours'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: mintColor.withOpacity(0.85)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label · $hours',
                        style: TextStyle(
                          color: subColor,
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (nudge.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              nudge,
              style: TextStyle(
                color: suggest ? mintColor.withOpacity(0.95) : subColor,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRainAlertCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor =
        isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final iconBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final textColor = Theme.of(context).colorScheme.onSurface;

    String locality = userZone ?? 'your area';
    locality = locality.replaceAll(
        RegExp(r' dark store zone', caseSensitive: false), '');
    locality = locality.replaceAll(RegExp(r' zone', caseSensitive: false), '');
    locality = locality.trim();
    if (locality.isEmpty) locality = 'your area';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.thunderstorm_rounded, color: mintColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboard_rain_alert.toUpperCase(),
                  style: TextStyle(
                    color: mintColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${l10n.dashboard_high_risk_prefix} $locality.\n${l10n.dashboard_secure_coverage}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/policy'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: mintColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.dashboard_activate,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF0a0b0a) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: isDark ? const Color(0xFF0a0b0a) : Colors.white,
                      size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveNudgeCard(AppLocalizations l10n) {
    if (nudgeData == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF0D1410) : const Color(0xFFE8F5E9);
    final mintColor =
        isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;

    final t = DynamicTranslator.of(context);
    final date =
        t.translateSync(nudgeData!['nudge_date'] as String? ?? 'Friday');
    final prob = nudgeData!['probability_percentage']?.toString() ?? '85';
    final desc = t.translateSync(
        nudgeData!['description'] as String? ?? 'Heavy rain expected.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mintColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: mintColor.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: mintColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'PROPHET AI NUDGE',
                style: TextStyle(
                  color: mintColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🌧️ $prob% Risk of Heavy Rain on $date',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            policyData != null
                ? '$desc\nYour active ${policyData!['plan_name']} will auto-cover any washout shifts.'
                : '$desc\nCoverage starts next Monday — activate quarterly plan now to secure your income.',
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivenessHUD(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final hintColor = theme.colorScheme.onSurface.withOpacity(0.4);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mintColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Shift Stats Panel
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                _buildRadarIndicator(mintColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SATELLITE PROTECTION ACTIVE', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: mintColor, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _statItem('Distance', '${LocationService.instance.traveledDistance.toStringAsFixed(2)} km', theme),
                          Container(width: 1, height: 20, color: theme.dividerColor, margin: const EdgeInsets.symmetric(horizontal: 16)),
                          _statItem('Accuracy', '${ShiftTrackingService.instance.lastAccuracy.round()}m', theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Live Feed Ticker
          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _events.length > 5 ? 5 : _events.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final event = _events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('[${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}] ', 
                        style: TextStyle(fontSize: 10, color: hintColor, fontFamily: 'monospace')),
                      Expanded(
                        child: Text(event.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w500)),
                      ),
                      if (index == 0) Icon(Icons.circle, size: 6, color: mintColor),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4))),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildRadarIndicator(Color mintColor) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...[1, 2].map((i) => Container(
              width: 44 * (1 + _radarController.value * 0.5 * i),
              height: 44 * (1 + _radarController.value * 0.5 * i),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: mintColor.withOpacity(1 - _radarController.value)),
              ),
            )),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: mintColor, shape: BoxShape.circle),
              child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 24),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCards(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        if (ShiftTrackingService.instance.status == ShiftStatus.offline) ...[
          BatteryOptimizationPrompt(onAllGranted: () async {
            // Guard: don't start if already active or going online
            if (_isGoingOnline ||
                ShiftTrackingService.instance.status != ShiftStatus.offline) {
              return;
            }

            // Request permissions BEFORE state change to prevent UI overlay deadlocks
            if (!kIsWeb) {
              await [
                Permission.notification,
                Permission.activityRecognition,
              ].request();
              
              final locStatus = await Permission.locationAlways.request();
              final batStatus = await Permission.ignoreBatteryOptimizations.request();
              
              if (locStatus.isPermanentlyDenied || batStatus.isPermanentlyDenied) {
                await openAppSettings();
                return;
              }
              if (!locStatus.isGranted && !await Permission.locationWhenInUse.status.isGranted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Location permission required')));
                 return;
              }
            }

            setState(() => _isGoingOnline = true);
            // permission_handler is not implemented on web (UnimplementedError).
            if (kIsWeb) {
              try {
                final zone =
                    userZone?.isNotEmpty == true ? userZone! : 'Local Zone';
                await ShiftTrackingService.instance.startShift(zone);
                AppEvents.instance.profileUpdated();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not go online on web: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isGoingOnline = false);
              }
              return;
            }
            
            try {
              final gpsEnabled = await Geolocator.isLocationServiceEnabled();
              if (!gpsEnabled) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please turn on device location to go online')),
                  );
                }
                setState(() => _isGoingOnline = false);
                return;
              }

              try {
                final position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                ).timeout(const Duration(seconds: 15));
                await StorageService.instance.setLastLat(position.latitude);
                await StorageService.instance.setLastLng(position.longitude);
              } catch (gpsError) {
                print('[GoOnline] GPS timeout: $gpsError — using last known');
              }
              // Use real zone from storage, no hardcoded fallback
              final zone =
                  userZone?.isNotEmpty == true ? userZone! : 'Local Zone';
              await ShiftTrackingService.instance.startShift(zone);
              AppEvents.instance.profileUpdated();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You are online.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              print('[GoOnline] ERROR: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not go online: $e')),
                );
              }
            } finally {
              if (mounted) setState(() => _isGoingOnline = false);
            }
          }),
          const SizedBox(height: 16),
        ],
        
        // ── Liveness HUD (Only shown when Online) ──
        if (ShiftTrackingService.instance.status != ShiftStatus.offline) ...[
          _buildLivenessHUD(context),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.shield_outlined,
                l10n.dashboard_modular,
                l10n.dashboard_add_coverage,
                () => context.push(AppRoutes.policy),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                Icons.article_outlined,
                l10n.dashboard_legal,
                l10n.dashboard_view_cert,
                () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.dashboard_generating_cert),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                  // Parse real dates from the new schema field names
                  final rawStart = policyData?['coverage_start'] as String?
                      ?? policyData?['start_date'] as String?;
                  final rawEnd   = policyData?['commitment_end'] as String?
                      ?? policyData?['paid_until'] as String?
                      ?? policyData?['end_date'] as String?;
                  final policyId = policyData?['id'] as String? ?? 'HS-PENDING';
                  final tier     = policyData?['plan_tier'] as String? ?? 'standard';
                  final premium  = PlanTierPrice.fromString(tier).weeklyPremium;
                  await PdfGenerator.generateAndPreviewCertificate(
                    name:          userName ?? 'Hustlr Worker',
                    zone:          userZone ?? 'Your Zone',
                    planName:      policyData?['plan_name'] as String? ?? 'Standard Shield',
                    policyNumber:  'HS-${policyId.substring(0, 8).toUpperCase()}',
                    coverageStart: rawStart != null ? DateTime.tryParse(rawStart) : null,
                    coverageEnd:   rawEnd   != null ? DateTime.tryParse(rawEnd)   : null,
                    weeklyPremium: premium,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      IconData icon, String kicker, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor =
        isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final iconBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final subtextColor =
        isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: mintColor, size: 22)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusBanner(BuildContext context,
      {required bool isGpsOff}) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.errorContainer;
    final fg = theme.colorScheme.onErrorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_off_rounded, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isGpsOff
                      ? 'Turn on GPS before going online'
                      : 'Location access is incomplete',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isGpsOff
                ? 'You can still browse the app, but shift protection and live zone tracking need device location turned on.'
                : 'You can keep using Hustlr normally. We will ask again only when you need protected tracking.',
            style: theme.textTheme.bodyMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              if (isGpsOff) {
                await Geolocator.openLocationSettings();
              } else {
                await openAppSettings();
              }
              _checkLocationPermission();
            },
            child: Text(isGpsOff ? 'Turn On GPS' : 'Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedPayoutsCard(
      int amount, BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor =
        isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final pinkColor =
        isDark ? const Color(0xFFff8ba0) : const Color(0xFFE91E63);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor =
        isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.shadowPolicy),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.savings_rounded, color: pinkColor, size: 32),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: mintColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.dashboard_see_why,
                        style: TextStyle(
                          color: mintColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Manrope',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: mintColor, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '₹$amount',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.2,
                fontFamily: 'Manrope',
              ),
            ),
            Text(
              l10n.dashboard_missed_payouts,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dashboard_potential_loss,
              style: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 DEBUG MODE — TESTING ONLY',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Divider(color: Colors.red.withOpacity(0.3)),

          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(60, 28),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 10),
                ),
                onPressed: () => _loadDashboardData(),
                child: const Text('REFRESH',
                    style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(60, 28),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 10),
                ),
                onPressed: () {
                  // Simulate a rain event locally for UI
                  if (mounted) {
                    setState(() {
                      disruptionData = {
                        'active': true,
                        'trigger_type': 'Heavy Rain',
                        'zone': userZone ?? 'Your Zone',
                      };
                      activeDisruption = disruptionData;
                    });
                  }
                },
                child:
                    const Text('RAIN', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: const Size(60, 28),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 10),
                ),
                onPressed: () => _checkLocationPermission(),
                child: const Text('GPS', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FraudSensorService.mockFraudSpoofing
                      ? Colors.green
                      : Colors.grey[800],
                  minimumSize: const Size(60, 28),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 10),
                ),
                onPressed: () async {
                  var newVal = !FraudSensorService.mockFraudSpoofing;
                  if (mounted) {
                    setState(() {
                      FraudSensorService.mockFraudSpoofing = newVal;
                    });
                    if (newVal) {
                      await StorageService.instance.setLastLat(13.0012);
                      await StorageService.instance.setLastLng(80.2565);
                      setState(() {
                        disruptionData = {
                          'active': true,
                          'trigger_type': 'Heavy Rain',
                          'zone': userZone ?? 'Your Zone',
                          'weather_source': 'mock_spoof',
                          'rain_mm': 72.4,
                          'severity': 0.85,
                        };
                        activeDisruption = disruptionData;
                      });
                      AppEvents.instance.claimUpdated();
                      AppEvents.instance.walletUpdated();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('🌧 SPOOF ON — Rain disruption injected'),
                          backgroundColor: Color(0xFF10B981)));
                    } else {
                      setState(() {
                        activeDisruption = null;
                        disruptionData = null;
                      });
                    }
                    LocationService.instance.updateFromGps(
                        LocationService.instance.currentLat,
                        LocationService.instance.currentLon);
                  }
                },
                child: Text(
                    FraudSensorService.mockFraudSpoofing
                        ? 'SPOOF (ON)'
                        : 'SPOOF (OFF)',
                    style: const TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _enableLiveML ? Colors.amber[800] : Colors.grey[800],
                  minimumSize: const Size(60, 28),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 10),
                ),
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _enableLiveML = !_enableLiveML;
                    });
                    if (_enableLiveML) {
                      _fetchLiveMLData(
                          policyData?['plan_tier'] ?? 'Standard Shield');
                    } else {
                      setState(() {
                        liveDynamicPrice = null;
                        liveIssScore = null;
                      });
                    }
                  }
                },
                child: Text(_enableLiveML ? 'ML SYNC (ON)' : 'ML SYNC (OFF)',
                    style: const TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(60, 28),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontSize: 10),
                ),
                onPressed: () async {
                  await StorageService.clearAll();
                  try {
                    final box = Hive.box('appData');
                    await box.put('isLoggedIn', false);
                    await box.put('isDemoSession', false);
                    await box.put('onboardingComplete', false);
                  } catch (_) {}
                  if (context.mounted) context.go(AppRoutes.login);
                },
                child:
                    const Text('LOGOUT', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _DebugHeader('--- USER STATE ---'),
          _DebugRow('USER ID', userId ?? 'NULL'),
          _DebugRow('NAME', userName ?? 'NULL'),
          _DebugRow('ZONE', userZone ?? 'NULL'),

          _DebugHeader('--- POLICY STATE ---'),
          _DebugRow('POLICY ID', policyData?['id']?.toString() ?? 'NULL'),
          _DebugRow(
              'PLAN TIER', policyData?['plan_tier']?.toString() ?? 'NULL'),
          _DebugRow('WEEKLY PREMIUM',
              policyData?['weekly_premium']?.toString() ?? 'NULL'),
          _DebugRow('STATUS', policyData?['status']?.toString() ?? 'NULL'),

          _DebugHeader('--- WALLET STATE ---'),
          Builder(builder: (context) {
            final rawBal = (walletData?['balance'] as num?)?.toInt();
            String balStr = 'NULL';
            if (rawBal != null) {
              balStr =
                  rawBal < 0 ? '0 (paid: ${rawBal.abs()})' : rawBal.toString();
            }
            return _DebugRow('BALANCE', balStr);
          }),
          _DebugRow('TOTAL PAYOUTS',
              walletData?['total_payouts']?.toString() ?? 'NULL'),
          _DebugRow('TOTAL PREMIUMS',
              walletData?['total_premiums']?.toString() ?? 'NULL'),
          _DebugRow('TRANSACTION COUNT',
              (walletData?['transactions'] as List?)?.length.toString() ?? '0'),

          _DebugHeader('--- DISRUPTION STATE ---'),
          _DebugRow(
              'WEATHER SOURCE',
              // API sends 'source'; some older responses have 'station'
              weatherData?['source']?.toString()
                  ?? weatherData?['station']?.toString()
                  ?? 'NULL'),
          _DebugRow('RAIN MM', '${weatherData?['rainfall_mm_1h'] ?? 'NULL'}'),
          _DebugRow('TEMP', '${weatherData?['temp_celsius'] ?? 'NULL'}°C'),
          _DebugRow('TRIGGER ACTIVE',
              disruptionData?['active']?.toString() ?? 'false'),
          _DebugRow('TRIGGER TYPE',
              disruptionData?['trigger_type']?.toString() ?? 'NONE'),

          _DebugHeader('--- API STATE ---'),
          _DebugRow('BACKEND URL', ApiService.baseUrl),
          const SizedBox(height: 8),
          // ── Live API Health Check ──────────────────────────────────
          if (_apiHealthStatus.isEmpty)
            GestureDetector(
              onTap: _checkApiHealth,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('▶ RUN API HEALTH CHECK',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            )
          else if (_apiHealthStatus['_loading'] == 'true')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF3FFF8B))),
                SizedBox(width: 10),
                Text('Pinging endpoints...',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            )
          else ...[
            ..._apiHealthStatus.entries.map((e) => _DebugRow(e.key, e.value)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _checkApiHealth,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('↻ RE-RUN CHECK',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          _DebugHeader('--- LOCATION STATE ---'),
          _DebugRow('LOCATION PERMISSION', _locationPermissionStatus),
          _DebugRow('LAST GPS LAT',
              _lastLat == 0.0 ? 'NO FIX YET' : _lastLat.toStringAsFixed(6)),
          _DebugRow('LAST GPS LNG',
              _lastLng == 0.0 ? 'NO FIX YET' : _lastLng.toStringAsFixed(6)),
          _DebugRow('ZONE DEPTH SCORE', _zoneDepthScore.toStringAsFixed(1)),
          _DebugRow(
              'BACKGROUND TRACKING', _backgroundTrackingActive.toString()),
        ],
      ),
    );
  }

  Widget _buildSystemStatusFeed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1c1f1c) : const Color(0xFFF0F4F0);
    final textColor = isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          final time = "${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}";
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              children: [
                Text(
                  "[$time] ",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: event.isError ? Colors.red : textColor,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  event.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: event.isError ? Colors.red : textColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveStatsRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsColor = isDark ? const Color(0xFF3FFF8B) : const Color(0xFF2E7D32);
    final accuracy = ShiftTrackingService.instance.lastAccuracy;
    final distance = LocationService.instance.traveledDistance;

    return Row(
      children: [
        _buildStatItem(
          icon: Icons.gps_fixed_rounded,
          label: 'Accuracy',
          value: '${accuracy.toStringAsFixed(1)}m',
          color: statsColor,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.speed_rounded,
          label: 'Protected',
          value: '${distance.toStringAsFixed(2)} km',
          color: statsColor,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          icon: Icons.location_on_rounded,
          label: 'Depth',
          value: '${_zoneDepthScore.round()}%',
          color: statsColor,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1c1f1c) : const Color(0xFFE8F5E9);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: color.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugHeader extends StatelessWidget {
  final String title;
  const _DebugHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  final String keyName;
  final String valName;
  const _DebugRow(this.keyName, this.valName);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$keyName: $valName',
      style: const TextStyle(
        color: Colors.greenAccent,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
  }
}
