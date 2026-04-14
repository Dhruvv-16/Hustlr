import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/location_service.dart';

import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/mobile_container.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/income_tip_card.dart';
import '../../widgets/hustlr_bottom_nav.dart';
import '../../services/notification_service.dart';
import '../../widgets/shift_status_dot.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/pdf_generator.dart';

import '../../features/shared/widgets/battery_optimization_prompt.dart';
import '../../features/shared/widgets/live_persona_panel.dart';
import '../../services/shift_tracking_service.dart';
import '../../services/fraud_sensor_service.dart';
import '../../services/dynamic_translator.dart';
import '../../services/app_events.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
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
  Timer? _disruptionRefreshTimer;
  StreamSubscription<Position>? _locationStream;
  
  // Stream subscriptions
  StreamSubscription? _policySub;
  StreamSubscription? _walletSub;
  StreamSubscription? _claimSub;
  
  // Realtime Gen ML Status
  int? liveIssScore;
  double? liveDynamicPrice;

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
    _disruptionRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (!mounted) return;
      _loadDashboardData();
    });

    _policySub = AppEvents.instance.onPolicyUpdated.listen((_) async {
      await _loadDashboardData();
      if (policyData != null) {
        final premiumRaw = policyData!['policy_card_premium'];
        final premium = (premiumRaw is num) ? premiumRaw.toDouble() : double.tryParse(premiumRaw.toString()) ?? 60.0;
        NotificationService.instance.addPremiumDeducted(premium.round());
      }
    });
    _walletSub = AppEvents.instance.onWalletUpdated.listen((_) => _loadDashboardData());
    _claimSub = AppEvents.instance.onClaimUpdated.listen((_) => _loadDashboardData());
    // AppEvents streams already wired above.
  }

  /// Get a one-shot GPS fix immediately on mount so the debug panel shows
  /// real coordinates without requiring the user to physically move first.
  Future<void> _fetchInitialLocation() async {
    try {
      final hasPermission = await Permission.locationWhenInUse.isGranted;
      if (!hasPermission) return;
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
        final premData = await ApiService.instance.getDynamicPremium(tier, score);
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
        final res = await http.get(
          Uri.parse('$base$path'),
        ).timeout(const Duration(seconds: 8));
        return res.statusCode < 400 ? '✅ ${res.statusCode}' : '❌ ${res.statusCode}';
      } on TimeoutException {
        return '⏱ TIMEOUT';
      } catch (e) {
        return '❌ ERR';
      }
    }

    results['GET /health']          = await ping('/health');
    if (userId != null) {
      results['GET /workers/:id']   = await ping('/workers/$userId');
      results['GET /policies/:id']  = await ping('/policies/$userId');
      results['GET /wallet/:id']    = await ping('/wallet/$userId');
      results['GET /claims/:id']    = await ping('/claims/$userId');
      final zone = Uri.encodeComponent(userZone ?? '');
      results['GET /disruptions']   = await ping('/disruptions/$zone');
    } else {
      results['NOTE'] = 'Log in first for user-scoped endpoints';
    }

    if (mounted) setState(() => _apiHealthStatus = results);
  }

  Future<void> _checkLocationPermission() async {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAllPermissions();
    }
  }

  Future<void> _recheckAllPermissions() async {
    final locationPerm = await Geolocator.checkPermission();
    final notifPerm    = await Permission.notification.status;
    final activityPerm = await Permission.activityRecognition.status;

    final locationOk = locationPerm == LocationPermission.always ||
                       locationPerm == LocationPermission.whileInUse;
    final allGranted = locationOk && notifPerm.isGranted && activityPerm.isGranted;

    if (mounted) {
      setState(() {
        _backgroundTrackingActive = locationPerm == LocationPermission.always;
        _locationPermissionStatus = locationPerm.toString();
      });
      // If all granted and shift not already active, start tracking
      if (allGranted && ShiftTrackingService.instance.status == ShiftStatus.offline) {
        final zone = userZone ?? 'Unknown Zone';
        await ShiftTrackingService.instance.startShift(zone);
      }
    }
  }

  void _onLocationUpdate() {
    if (mounted) setState(() {});
  }

  void _onShiftUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
    userId = await StorageService.instance.getUserId();
    userZone = await StorageService.instance.getUserZone();
    userName = await StorageService.instance.getUserName();

    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final policyRes = await ApiService.instance.getPolicy(userId!);
      final walletRes = await ApiService.instance.getWallet(userId!);
      Map<String, dynamic> disruptionRes = {};
      try {
        int? issScore;
        final w = await ApiService.instance.getWorkerById(userId!);
        final rawIss = w['iss_score'];
        if (rawIss is num) {
          issScore = rawIss.round().clamp(0, 100);
        }
        disruptionRes = await ApiService.instance.getDisruptions(
          userZone ?? '',
        );
      } catch (_) {}

      final rawPolicy = policyRes['policy'] as Map<String, dynamic>?;
      final tier = rawPolicy?['plan_tier'] as String?;
      policyData = rawPolicy == null
          ? null
          : {
              ...rawPolicy,
              'plan_name': _planDisplayName(tier),
            };

      final events = disruptionRes['disruptions'] as List<dynamic>? ?? [];
      final active = disruptionRes['active'] == true;
      final rawWeather = disruptionRes['weather'] as Map<String, dynamic>?;
      final rawNudge = disruptionRes['predictive_nudge'] as Map<String, dynamic>?;
      final rawAdvisor = disruptionRes['work_advisor'] as Map<String, dynamic>?;

      Map<String, dynamic>? latestDisruption;
      if (!active || events.isEmpty) {
        disruptionData = const {'active': false};
      } else {
        latestDisruption = events.first as Map<String, dynamic>;
        disruptionData = {
          'active': true,
          'trigger_type': latestDisruption['display_name'] as String? ?? 
              _disruptionTriggerLabel(latestDisruption['trigger_type'] as String?),
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
    return labels[t] ?? (t.isNotEmpty ? '${t[0].toUpperCase()}${t.substring(1).replaceAll('_', ' ')}' : 'Rain');
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
        body: Center(child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        )),
      );
    }

    final isLocationDenied = _locationPermissionStatus.contains('permanentlyDenied');
    final isGpsOff = _locationPermissionStatus == 'GPS_DISABLED_ON_DEVICE';

    if (isLocationDenied || isGpsOff) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_disabled,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Location Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isGpsOff
                      ? 'Your physical GPS sensor is turned off. Hustlr requires active GPS to track your delivery routes and authenticate weather claims.'
                      : 'Hustlr requires "While using the app" or "Always" location access to protect your income during deliveries. "Only this time" is not supported.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (isGpsOff) {
                      await Geolocator.openLocationSettings();
                    } else {
                      await openAppSettings();
                    }
                    _checkLocationPermission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(isGpsOff ? 'Turn On GPS' : 'Open Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final planName = policyData?['plan_name'] ?? 'Standard Shield';
    
    String titleCase(String text) {
      if (text.isEmpty) return text;
      return text.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    
    final displayUserName = titleCase(userName ?? 'Karthik');
    final rawPremium = policyData?['weekly_premium']?.toString();
    final String premium = liveDynamicPrice != null ? liveDynamicPrice!.toStringAsFixed(0) : (rawPremium == '50' ? '49' : rawPremium ?? 
        (planName == 'Basic Shield' ? '29' : 
         planName == 'Standard Shield' ? '49' : 
          planName == 'Full Shield' ? '79' : '109'));
    
    // Fallback to MockData shadowMissed or a positive value, never wallet balance!
    final pAmount = (policyData?['missed_payouts'] as num?)?.toInt()?.abs() ?? 680;

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
                      const SizedBox(height: 32),
                      _buildTitleSection(l10n, displayUserName),
                      const SizedBox(height: 20),
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
                      _buildActivePolicyCard(planName, premium, l10n),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111311) : const Color(0xFFF0F4F0),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          children: [
                            _buildActionCards(context, l10n),
                            if (policyData != null) ...[
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
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          onLongPress: () => showLivePersonaPanel(context, onSubmit: _loadDashboardData),
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
        const ShiftStatusDot(),
        const Spacer(),
        _buildMintIconBtn(Icons.headset_mic_rounded, () => context.push(AppRoutes.support), mintColor, isDark),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
            color: _debugMode ? Colors.red : Colors.grey,
          ),
          onPressed: () => setState(() => _debugMode = !_debugMode),
        ),
        const SizedBox(width: 8),
        _buildMintIconBtn(Icons.notifications_rounded, () => context.push(AppRoutes.notifications), mintColor, isDark),
      ],
    );
  }

  Widget _buildMintIconBtn(IconData icon, VoidCallback onTap, Color mintColor, bool isDark) {
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
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final deepContainer = isDark ? const Color(0xFF003324) : const Color(0xFFE8F5E9);
    final subtextColor = isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.wallet_title,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Manrope',
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
                    (DynamicTranslator.of(context).translate(userZone) ?? userZone ?? 'BENGALURU, KA').toUpperCase(),
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

  Widget _buildActivePolicyCard(String planName, String premium, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtleText = isDark ? const Color(0xFFe1e3de) : const Color(0xFF4A6741);
    final shadowColor = isDark 
        ? const Color(0xFF3fff8b).withOpacity(0.04) 
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
                _isMLFetching ? 'CALCULATING AI PREMIUM...' : (liveDynamicPrice != null ? 'ML ADJUSTED PREMIUM' : 'YOUR WEEKLY PREMIUM'),
                style: TextStyle(
                  color: _isMLFetching ? Colors.orangeAccent : (liveDynamicPrice != null ? Colors.amberAccent : subtleText),
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
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent)),
                    )
                  else
                    Text(
                      '₹$premium',
                      style: TextStyle(
                        color: liveDynamicPrice != null ? Colors.amberAccent : mintColor,
                        fontSize: liveDynamicPrice != null ? 30 : 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  if (!_isMLFetching)
                    Text(
                      liveDynamicPrice != null ? ' (ML Adjusted)' : '/ week',
                      style: TextStyle(
                        color: liveDynamicPrice != null ? Colors.amberAccent : subtleText,
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
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCoverageChip(l10n.claims_heavy_rain.toUpperCase(), Icons.water_drop_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_extreme_heat.toUpperCase(), Icons.wb_sunny_rounded, mintColor, isDark),
              _buildCoverageChip(l10n.claims_platform_downtime.toUpperCase(), Icons.security_rounded, mintColor, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageChip(String label, IconData icon, Color mintColor, bool isDark) {
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
    final cardColor = isDark ? const Color(0xFF141614) : const Color(0xFFF8FAF8);
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = textColor.withOpacity(0.65);

    final t = DynamicTranslator.of(context);
    final esi = (a['earning_stability_index'] as num?)?.round() ?? 0;
    final band = t.translate(a['stability_band_label'] as String? ?? 'Earning outlook');
    final headline = t.translate(a['headline'] as String? ?? '');
    final nudge = t.translate(a['coverage_nudge'] as String? ?? '');
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              final label = t.translate(m['label'] as String? ?? '');
              final hours = m['hours'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: mintColor.withOpacity(0.85)),
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
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final iconBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final textColor = Theme.of(context).colorScheme.onSurface;

    String locality = userZone ?? 'your area';
    locality = locality.replaceAll(RegExp(r' dark store zone', caseSensitive: false), '');
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
    final cardColor = isDark ? const Color(0xFF0D1410) : const Color(0xFFE8F5E9);
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    final t = DynamicTranslator.of(context);
    final date = t.translate(nudgeData!['nudge_date'] as String? ?? 'Friday');
    final prob = nudgeData!['probability_percentage']?.toString() ?? '85';
    final desc = t.translate(nudgeData!['description'] as String? ?? 'Heavy rain expected.');
    
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

  Widget _buildActionCards(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        if (ShiftTrackingService.instance.status == ShiftStatus.offline) ...[
          BatteryOptimizationPrompt(onAllGranted: () async {
            // Guard: don't start if already active or loading
            if (isLoading || ShiftTrackingService.instance.status != ShiftStatus.offline) return;
            setState(() => isLoading = true);
            try {
              final permStatus = await Permission.locationWhenInUse.status;
              if (!permStatus.isGranted) {
                final result = await Permission.locationWhenInUse.request();
                if (!result.isGranted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission required')));
                  setState(() => isLoading = false);
                  return;
                }
              }
              final bgPerm = await Permission.locationAlways.status;
              if (!bgPerm.isGranted) {
                await Permission.locationAlways.request();
              }
              final notifPerm = await Permission.notification.status;
              if (!notifPerm.isGranted) {
                await Permission.notification.request();
              }
              final actPerm = await Permission.activityRecognition.status;
              if (!actPerm.isGranted) {
                await Permission.activityRecognition.request();
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
              final zone = userZone?.isNotEmpty == true ? userZone! : 'Local Zone';
              await ShiftTrackingService.instance.startShift(zone);
              AppEvents.instance.profileUpdated();
            } catch (e) {
              print('[GoOnline] ERROR: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not go online: $e')),
                );
              }
            } finally {
              if (mounted) setState(() => isLoading = false);
            }
          }),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
              await PdfGenerator.generateAndPreviewCertificate();
            },
          ),
        ),
      ],
    ),
   ],
  );
}

  Widget _buildActionCard(IconData icon, String kicker, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final iconBg = isDark ? const Color(0xFF003D2A) : const Color(0xFFE8F5E9);
    final subtextColor = isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);
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
               child: Icon(icon, color: mintColor, size: 22)
            ),
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

  Widget _buildMissedPayoutsCard(int amount, BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1c1f1c) : Colors.white;
    final mintColor = isDark ? const Color(0xFF3fff8b) : const Color(0xFF1B5E20);
    final pinkColor = isDark ? const Color(0xFFff8ba0) : const Color(0xFFE91E63);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtextColor = isDark ? const Color(0xFF91938d) : const Color(0xFF4A6741);

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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      Icon(Icons.arrow_forward_rounded, color: mintColor, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '₹$amount ${l10n.dashboard_missed_payouts}',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.2,
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
                child: const Text('REFRESH', style: TextStyle(color: Colors.white)),
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
                child: const Text('RAIN', style: TextStyle(color: Colors.white)),
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
                  backgroundColor: FraudSensorService.mockFraudSpoofing ? Colors.green : Colors.grey[800],
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🌧 SPOOF ON — Rain disruption injected'), backgroundColor: Color(0xFF10B981))
                      );
                    } else {
                      setState(() {
                        activeDisruption = null;
                        disruptionData = null;
                      });
                    }
                    LocationService.instance.updateFromGps(LocationService.instance.currentLat, LocationService.instance.currentLon);
                  }
                },
                child: Text(FraudSensorService.mockFraudSpoofing ? 'SPOOF (ON)' : 'SPOOF (OFF)', style: const TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _enableLiveML ? Colors.amber[800] : Colors.grey[800],
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
                       _fetchLiveMLData(policyData?['plan_tier'] ?? 'Standard Shield');
                    } else {
                       setState(() { liveDynamicPrice = null; liveIssScore = null; });
                    }
                  }
                },
                child: Text(_enableLiveML ? 'ML SYNC (ON)' : 'ML SYNC (OFF)', style: const TextStyle(color: Colors.white)),
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
                child: const Text('LOGOUT', style: TextStyle(color: Colors.white)),
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
          _DebugRow('PLAN TIER', policyData?['plan_tier']?.toString() ?? 'NULL'),
          _DebugRow('WEEKLY PREMIUM', policyData?['weekly_premium']?.toString() ?? 'NULL'),
          _DebugRow('STATUS', policyData?['status']?.toString() ?? 'NULL'),

          _DebugHeader('--- WALLET STATE ---'),
          Builder(builder: (context) {
            final rawBal = (walletData?['balance'] as num?)?.toInt();
            String balStr = 'NULL';
            if (rawBal != null) {
              balStr = rawBal < 0 ? '0 (paid: ${rawBal.abs()})' : rawBal.toString();
            }
            return _DebugRow('BALANCE', balStr);
          }),
          _DebugRow('TOTAL PAYOUTS', walletData?['total_payouts']?.toString() ?? 'NULL'),
          _DebugRow('TOTAL PREMIUMS', walletData?['total_premiums']?.toString() ?? 'NULL'),
          _DebugRow('TRANSACTION COUNT', (walletData?['transactions'] as List?)?.length.toString() ?? '0'),

          _DebugHeader('--- DISRUPTION STATE ---'),
          _DebugRow('WEATHER SOURCE', weatherData?['station']?.toString() ?? 'NULL'),
          _DebugRow('RAIN MM', '${weatherData?['rainfall_mm_1h'] ?? 'NULL'}'),
          _DebugRow('TEMP', '${weatherData?['temp_celsius'] ?? 'NULL'}°C'),
          _DebugRow('TRIGGER ACTIVE', disruptionData?['active']?.toString() ?? 'false'),
          _DebugRow('TRIGGER TYPE', disruptionData?['trigger_type']?.toString() ?? 'NONE'),

          _DebugHeader('--- API STATE ---'),
          _DebugRow('BACKEND URL', ApiService.baseUrl),
          const SizedBox(height: 8),
          // ── Live API Health Check ──────────────────────────────────
          if (_apiHealthStatus.isEmpty)
            GestureDetector(
              onTap: _checkApiHealth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('▶ RUN API HEALTH CHECK',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            )
          else if (_apiHealthStatus['_loading'] == 'true')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3FFF8B))),
                SizedBox(width: 10),
                Text('Pinging endpoints...', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            )
          else ...[
            ..._apiHealthStatus.entries.map((e) =>
              _DebugRow(e.key, e.value)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _checkApiHealth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('↻ RE-RUN CHECK',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          _DebugHeader('--- LOCATION STATE ---'),
          _DebugRow('LOCATION PERMISSION', _locationPermissionStatus),
          _DebugRow('LAST GPS LAT', _lastLat == 0.0 ? 'NO FIX YET' : _lastLat.toStringAsFixed(6)),
          _DebugRow('LAST GPS LNG', _lastLng == 0.0 ? 'NO FIX YET' : _lastLng.toStringAsFixed(6)),
          _DebugRow('ZONE DEPTH SCORE', _zoneDepthScore.toStringAsFixed(1)),
          _DebugRow('BACKGROUND TRACKING', _backgroundTrackingActive.toString()),
        ],
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
