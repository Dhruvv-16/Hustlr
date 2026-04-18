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

  void _showPermissionsSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Keep sheet in sync with widget state
          final locAlways = _locationAlways;
          final locFg = _locationForegroundOnly;
          final batUnrestricted = _batteryUnrestricted;
          
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 10),
                    Text('Enable Protection', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hustlr needs background access to accurately track your zone and process automated payouts during disruptions.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 24),

                // Location Permission Row
                _PermissionRow(
                  icon: Icons.location_on_rounded,
                  label: locAlways
                      ? 'Location: Always Allow'
                      : locFg
                          ? 'Location: While Using App'
                          : 'Location Access',
                  subtitle: locAlways
                      ? 'Background tracking active'
                      : locFg
                          ? 'Upgrade to Always Allow'
                          : 'Required to track your zone',
                  isGranted: locAlways || locFg,
                  isWarning: locFg,
                  onFix: () async {
                    await _requestLocation();
                    setSheetState(() {});
                    if (mounted && _locationAlways && _batteryUnrestricted) {
                      Navigator.pop(sheetCtx);
                      widget.onAllGranted();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Battery Row
                _PermissionRow(
                  icon: Icons.battery_charging_full_rounded,
                  label: 'Unrestricted Battery',
                  subtitle: 'Prevents Android from killing the app',
                  isGranted: batUnrestricted,
                  onFix: () async {
                    await _requestBattery();
                    setSheetState(() {});
                    if (mounted && _locationAlways && _batteryUnrestricted) {
                      Navigator.pop(sheetCtx);
                      widget.onAllGranted();
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;

    if (_checking) {
      return SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 24, height: 24, 
            child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2)
          )
        ),
      );
    }

    final allGranted = _locationAlways && _batteryUnrestricted;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          if (allGranted) {
            widget.onAllGranted();
          } else {
            _showPermissionsSheet(context, theme);
          }
        },
        icon: Icon(allGranted ? Icons.power_settings_new_rounded : Icons.shield_outlined),
        label: Text(
          allGranted ? 'GO ONLINE' : 'Enable Protection to Go Online',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: allGranted ? primaryGreen : const Color(0xFFE88A00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: allGranted ? 0 : 2,
          shadowColor: allGranted ? Colors.transparent : const Color(0xFFE88A00).withOpacity(0.35),
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
