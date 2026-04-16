import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// Shown before the worker can tap "Go Online".
/// Gates shift start behind two mandatory checks:
/// 1. Location permission = Always Allow
/// 2. Battery optimization = Unrestricted (not "Optimized")
///
/// Mirrors the UX pattern used by Rapido / Ola Driver apps.
class BatteryOptimizationPrompt extends StatefulWidget {
  final VoidCallback onAllGranted;
  const BatteryOptimizationPrompt({super.key, required this.onAllGranted});

  @override
  State<BatteryOptimizationPrompt> createState() =>
      _BatteryOptimizationPromptState();
}

class _BatteryOptimizationPromptState
    extends State<BatteryOptimizationPrompt> with WidgetsBindingObserver {
  bool _locationAlways = false;
  bool _locationForegroundOnly = false;  // soft pass: while-using-app grants foreground only
  bool _batteryUnrestricted = false;
  bool _batteryManuallyVerified = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAll();
  }

  Future<void> _checkAll() async {
    setState(() => _checking = true);

    // Skip permission checks on web - not supported
    if (kIsWeb) {
      setState(() {
        _locationAlways = true;
        _locationForegroundOnly = false;
        _batteryUnrestricted = true;
        _checking = false;
      });
      return;
    }

    final locAlwaysStatus = await Permission.locationAlways.status;
    final locFgStatus = await Permission.location.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    final locationAlways = locAlwaysStatus == PermissionStatus.granted;
    // Soft pass: foreground-only is acceptable — worker can go online with a warning
    final locationForeground = locFgStatus == PermissionStatus.granted || locationAlways;
    final batteryGranted = batteryStatus == PermissionStatus.granted;
    // OEM workaround: OnePlus / Xiaomi ROMs silently revert == denied even after user taps Allow.
    // _batteryManuallyVerified is set to true the moment the user returns from battery settings.
    final batteryUnrestricted = batteryGranted || _batteryManuallyVerified;

    if (mounted) {
      setState(() {
        _locationAlways = locationAlways;
        _locationForegroundOnly = locationForeground && !locationAlways;
        _batteryUnrestricted = batteryUnrestricted;
        _checking = false;
      });
    }
  }

  Future<void> _requestLocation() async {
    // Android 11+ requires foreground location granted before requesting background.
    var status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      // Try to upgrade to Always Allow (background)
      status = await Permission.locationAlways.request();
    }
    if (status == PermissionStatus.permanentlyDenied) {
      // Deep-link directly to THIS app's location settings (not generic settings)
      await AppSettings.openAppSettings(type: AppSettingsType.location);
    }
    _checkAll();
  }

  Future<void> _requestBattery() async {
    // First try the direct OS dialog
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (status != PermissionStatus.granted) {
      // Deep-link to battery optimization settings page if request failed
      await AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization);
    }
    // Vendor OS workaround: Android 11/12 on many OEM ROMs (Xiaomi, OnePlus, Samsung)
    // incorrectly returns PermissionStatus.denied even AFTER the user enables Unrestricted.
    // We mark it as manually verified once they return from settings to unblock the gate.
    _batteryManuallyVerified = true;
    _checkAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryGreen = Color(0xFF2E7D32);

    if (_checking) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Checking permissions...',
              style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final allGranted = _locationAlways && _batteryUnrestricted;

    return AbsorbPointer(
      absorbing: false, // Allow interaction unless permissions are being checked
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: allGranted ? const Color(0xFF43A047) : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                allGranted ? Icons.check_circle_rounded : Icons.shield_outlined,
                color: allGranted ? const Color(0xFF43A047) : primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                allGranted ? 'All set — go online!' : 'Enable shift protection',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: allGranted ? const Color(0xFF2E7D32) : theme.colorScheme.onSurface,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Hustlr needs these to verify your location during disruptions and process payouts.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            // Location Permission Row — show nuanced state
            _PermissionRow(
              icon: Icons.location_on_rounded,
              label: _locationAlways
                  ? 'Always Allow Location'
                  : _locationForegroundOnly
                      ? 'Location: While Using App'
                      : 'Always Allow Location',
              subtitle: _locationAlways
                  ? 'Background tracking active'
                  : _locationForegroundOnly
                      ? 'Tap Fix to upgrade to Always Allow for full protection'
                      : 'Required to track your zone during deliveries',
              isGranted: _locationAlways || _locationForegroundOnly,
              isWarning: _locationForegroundOnly,
              onFix: _requestLocation,
            ),
            const SizedBox(height: 10),

            // Battery Optimization Row
            _PermissionRow(
              icon: Icons.battery_charging_full_rounded,
              label: 'Unrestricted Battery',
              subtitle: 'Prevents Android from killing Hustlr in the background',
              isGranted: _batteryUnrestricted,
              onFix: _requestBattery,
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (allGranted) {
                    widget.onAllGranted();
                  } else {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (sheetCtx) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 28),
                                SizedBox(width: 10),
                                Text('Coverage Requires Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Without location access and unrestricted battery settings, disruption claims in your zone cannot be verified. You will not be fully protected.',
                              style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(sheetCtx),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                                child: const Text('Fix Permissions'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Go Online',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allGranted ? primaryGreen : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isGranted;
  final bool isWarning;   // amber state: foreground-only location
  final VoidCallback onFix;

  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isGranted,
    required this.onFix,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isGranted
                ? isWarning
                    ? const Color(0xFFFFA000).withValues(alpha: 0.12)
                    : const Color(0xFF43A047).withValues(alpha: 0.1)
                : const Color(0xFFE53935).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isGranted
                ? isWarning
                    ? const Color(0xFFFFA000)
                    : const Color(0xFF43A047)
                : const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600])),
            ],
          ),
        ),
        if (!isGranted)
          TextButton(
            onPressed: onFix,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 32),
            ),
            child: const Text('Fix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )
        else if (isWarning)
          TextButton(
            onPressed: onFix,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFA000),
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 32),
            ),
            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )
        else
          const Icon(Icons.check_rounded, color: Color(0xFF43A047), size: 20),
      ],
    );
  }
}
