import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';
import '../services/mock_data_service.dart';
import '../services/location_service.dart';
import '../services/fraud_sensor_service.dart';
import 'restart_widget.dart';

class DemoControlsSheet extends StatefulWidget {
  const DemoControlsSheet({super.key});

  @override
  State<DemoControlsSheet> createState() => _DemoControlsSheetState();
}

class _DemoControlsSheetState extends State<DemoControlsSheet> {
  int _activePersona = -1;
  bool _isRunning = false;

  // ── Persona definitions ────────────────────────────────────
  static const List<Map<String, dynamic>> PERSONAS = [
    {
      'id':       'karthik',
      'name':     'Karthik, 24',
      'role':     'Standard Shield · Adyar Zone',
      'icon':     '🚴',
      'color':    Color(0xFF1976D2),
      'bg':       Color(0xFFE3F2FD),
      'tagline':  'Full parametric loop — rain → claim → payout',
      'features': [
        'Rain disruption auto-detected',
        'Fraud check passes (FPS 14)',
        'Tranche 1 (70%) credited in minutes',
        'Notification bell updates live',
        'Wallet balance increases',
      ],
      'steps': [
        'Rain alert appears on dashboard',
        'Claim created → PENDING',
        'Auto-approved in 3 seconds',
        'Wallet credited ₹105',
        'Push notification sent',
      ],
    },
    {
      'id':       'ravi',
      'name':     'Ravi, 31',
      'role':     'Full Shield · Velachery Zone',
      'icon':     '⚡',
      'color':    Color(0xFFE65100),
      'bg':       Color(0xFFFFF3E0),
      'tagline':  'Compound trigger — rain + platform outage',
      'features': [
        'Two triggers fire simultaneously',
        'Compound payout (130% rate)',
        'Full Shield daily cap ₹250',
        'Shadow policy tracking shown',
        'Predictive nudge displayed',
      ],
      'steps': [
        'Platform outage detected (78% failure rate)',
        'Rain cross-confirmed by IMD',
        'Compound trigger fires',
        'Payout ₹245 (compound rate)',
        'Wednesday nudge scheduled',
      ],
    },
    {
      'id':       'muthu',
      'name':     'Muthu, 28',
      'role':     'No Policy · Tambaram Zone',
      'icon':     '📊',
      'color':    Color(0xFF6A1B9A),
      'bg':       Color(0xFFF3E5F5),
      'tagline':  'Shadow policy — conversion nudge demo',
      'features': [
        'Uninsured worker tracked silently',
        'Missed payout calculated (₹680)',
        'Shadow policy nudge shown',
        'Policy comparison screen opens',
        'One-tap enrolment flow',
      ],
      'steps': [
        'Rain disruption hits Tambaram zone',
        'Shadow policy calculates ₹340 missed',
        'Second event adds ₹340 more',
        'Nudge: "You missed ₹680 this fortnight"',
        'Activate Standard Shield CTA shown',
      ],
    },
    {
      'id':       'fraudster',
      'name':     'Fraud Attempt',
      'role':     'GPS Spoofer · Adyar Zone',
      'icon':     '🛡️',
      'color':    Color(0xFFB71C1C),
      'bg':       Color(0xFFFFEBEE),
      'tagline':  'Fraud engine catches GPS spoofing in real time',
      'features': [
        'Zero GPS jitter detected',
        'FPS score spikes to 87',
        'Claim auto-flagged RED',
        'Provisional ₹200 only',
        'Human review queued',
      ],
      'steps': [
        'Claim submitted with gps_jitter=0.0',
        'Isolation Forest: anomaly detected',
        'Zero jitter override: FPS → 87',
        'Status: FLAGGED (not APPROVED)',
        'Auto-explanation sent to worker',
      ],
    },
    {
      'id':       'santhosh',
      'name':     'Santhosh, 26',
      'role':     'Standard Shield · OMR Zone',
      'icon':     '🏆',
      'color':    Color(0xFF1B5E20),
      'bg':       Color(0xFFE8F5E9),
      'tagline':  'Trust score + cashback — 4 clean weeks',
      'features': [
        'Worker Trust Score shown',
        'Gold tier badge displayed',
        'Clean week streak: 4 weeks',
        'Cashback ₹19.60 auto-credited',
        'Profile trust tier updated',
      ],
      'steps': [
        'Load worker with 4 clean weeks',
        'Sunday settlement triggers cashback',
        '10% of premiums returned (₹19.60)',
        'Trust score → 127 (Gold tier)',
        'Wallet shows cashback credit',
      ],
    },
    {
      'id':       'priya',
      'name':     'Priya, 33',
      'role':     'Standard Shield · T.Nagar Zone',
      'icon':     '🌐',
      'color':    Color(0xFF00695C),
      'bg':       Color(0xFFE0F2F1),
      'tagline':  'Internet zone blackout trigger',
      'features': [
        'Zone connectivity drops to 8%',
        'TRAI outage signal detected',
        'Blackout trigger fires automatically',
        'Payout ₹110 credited',
        'No GPS needed — self-validating',
      ],
      'steps': [
        'Ookla: T.Nagar avg speed 0.3 Mbps',
        'TRAI registry: Airtel outage logged',
        'Dual confirmation → AUTO_TRIGGER',
        'Claim created: internet_blackout',
        'Payout ₹77 (70% tranche)',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141614) : Colors.white;
    final surface = isDark ? const Color(0xFF1C1F1C)
                           : const Color(0xFFF4F6F4);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Demo Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFE1E3DE)
                              : const Color(0xFF0D1B0F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a persona to demo a specific feature set',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF91938D)
                              : const Color(0xFF4A6741),
                        ),
                      ),
                    ],
                  ),
                ),
                // Test Notification button
                TextButton(
                  onPressed: () {
                    NotificationService.instance.addWalletCredited(amount: 500);
                  },
                  child: const Text('Test Notif',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Reset button
                TextButton(
                  onPressed: _hardReset,
                  child: const Text('Hard Reset',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC62828), // Red for "surgical strike"
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Persona cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: PERSONAS.length,
              itemBuilder: (context, i) {
                final p = PERSONAS[i];
                final isActive = _activePersona == i;
                final color = p['color'] as Color;
                final bg = p['bg'] as Color;

                return GestureDetector(
                  onTap: _isRunning ? null : () => _runPersona(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark ? color.withOpacity(0.15) : bg)
                          : (isDark
                              ? const Color(0xFF1C1F1C)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Persona header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16,14,16,10),
                          child: Row(
                            children: [
                              Text(p['icon'] as String,
                                style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(p['name'] as String,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFFE1E3DE)
                                            : const Color(0xFF0D1B0F),
                                      ),
                                    ),
                                    Text(p['role'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF91938D)
                                            : const Color(0xFF4A6741),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status indicator
                              if (isActive && _isRunning)
                                SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: color,
                                  ),
                                )
                              else if (isActive && !_isRunning)
                                Icon(Icons.check_circle,
                                  color: color, size: 20)
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? color.withOpacity(0.15)
                                        : bg,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text('Run',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Tagline
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16,0,16,10),
                          child: Text(p['tagline'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ),

                        // Features list — shown when active
                        if (isActive) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16,10,16,4),
                            child: Text('FEATURES DEMONSTRATED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF91938D)
                                    : const Color(0xFF4A6741),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ...(p['features'] as List<String>)
                              .map((f) => Padding(
                                padding: const EdgeInsets.fromLTRB(16,2,16,2),
                                child: Row(
                                  children: [
                                    Icon(Icons.check,
                                      size: 13, color: color),
                                    const SizedBox(width: 6),
                                    Text(f,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFFE1E3DE)
                                            : const Color(0xFF0D1B0F),
                                      ),
                                    ),
                                  ],
                                ),
                              )),

                          // Steps — shown when running
                          if (_isRunning) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16,10,16,4),
                              child: Text('DEMO SEQUENCE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF91938D)
                                      : const Color(0xFF4A6741),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            ...(p['steps'] as List<String>)
                                .asMap()
                                .entries
                                .map((e) => Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16,2,16,2),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18, height: 18,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${e.key + 1}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(e.value,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFF91938D)
                                                : const Color(0xFF4A6741),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // --- SIMULATE ROAMING / HUB PROXIMITY ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.map_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('ROAMING SIMULATOR', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, 
                      letterSpacing: 1.0, color: theme.colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _hubSimButton('Kattankulathur', 12.8185, 80.0419),
                      const SizedBox(width: 10),
                      _hubSimButton('Adyar (Flood)', 13.0067, 80.2206),
                      const SizedBox(width: 10),
                      _hubSimButton('HSR (Outage)', 12.9081, 77.6476),
                      const SizedBox(width: 10),
                      _hubSimButton('Indiranagar', 12.9784, 77.6408),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text('Tap to teleport persona to a Dark Store Hub. Hudson will detect the move instantly.',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          // --- ML SYNC ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('ML SYNC', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, 
                      letterSpacing: 1.0, color: theme.colorScheme.primary)),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Force ML Resync', style: theme.textTheme.bodyMedium),
                  subtitle: Text('Pulls latest ISS & Pricing from proxy', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  trailing: OutlinedButton(
                    onPressed: () {
                      LocationService.instance.addEvent("ML Data Synced from Python Backend");
                      _showSuccess("ML synchronization requested.");
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SYNC NOW', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // --- EXTERNAL DISRUPTIONS ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('EXTERNAL DISRUPTIONS', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, 
                      letterSpacing: 1.0, color: theme.colorScheme.primary)),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Trigger Heavy Rain', style: theme.textTheme.bodyMedium),
                  subtitle: Text('Mocks OWM alert & starts claim', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    onPressed: () {
                      context.read<MockDataService>().triggerRainDisruption();
                      Navigator.pop(context);
                    },
                    child: const Text('FIRE', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Trigger Heatwave', style: theme.textTheme.bodyMedium),
                  subtitle: Text('Mocks extreme temperature alert', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
                    onPressed: () {
                      context.read<MockDataService>().triggerExtremeHeat();
                      Navigator.pop(context);
                    },
                    child: const Text('FIRE', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // --- SPOOF OPTIONS ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_off_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('SPOOF OPTIONS', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, 
                      letterSpacing: 1.0, color: theme.colorScheme.primary)),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Mock GPS Spoofing (Fraud)', style: theme.textTheme.bodyMedium),
                  subtitle: Text('Sets GPS jitter to 0.0 & isMocked=true', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  value: FraudSensorService.mockFraudSpoofing,
                  activeColor: Colors.redAccent,
                  onChanged: (val) {
                    setState(() => FraudSensorService.mockFraudSpoofing = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hubSimButton(String label, double lat, double lon) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: () {
        LocationService.instance.forceMockLocation(label, lat, lon, depthScore: 0.95);
        _showStep('Teleported to $label Hub');
      },
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
    );
  }

  // ── Persona runners ────────────────────────────────────────

  Future<void> _runPersona(int index) async {
    setState(() {
      _activePersona = index;
      _isRunning = true;
    });

    final persona = PERSONAS[index];

    switch (persona['id'] as String) {
      case 'karthik':  await _runKarthik();  break;
      case 'ravi':     await _runRavi();     break;
      case 'muthu':    await _runMuthu();    break;
      case 'fraudster':await _runFraudster();break;
      case 'santhosh': await _runSanthosh(); break;
      case 'priya':    await _runPriya();    break;
    }

    setState(() => _isRunning = false);
  }

  // Karthik — standard rain claim, full parametric loop
  Future<void> _runKarthik() async {
    final userId = await StorageService.instance.getUserId();
    if (userId == null) return;

    try {
      // 1. Show rain alert on dashboard
      _showStep('Rain alert firing in Adyar zone...');
      await Future.delayed(const Duration(milliseconds: 800));

      // 2. Create claim
      _showStep('Creating rain claim...');
      context.read<MockDataService>().triggerRainDisruption();

      // 3. Fire notification
      NotificationService.instance.addClaimCreated(
        triggerType: 'Heavy Rain',
        amount: 105,
      );

      await Future.delayed(const Duration(seconds: 2));

      // 4. Auto-approve fires (backend does this after 5s)
      _showStep('Claim auto-approved...');
      NotificationService.instance.addClaimApproved(105);
      NotificationService.instance.addWalletCredited(amount: 105);

      _showSuccess('Karthik received ₹105. Navigate to Claims and Wallet to see.');

    } catch (e) {
      _showError('Demo error: $e');
    }
  }

  // Ravi — compound trigger
  Future<void> _runRavi() async {
    final userId = await StorageService.instance.getUserId();
    if (userId == null) return;

    try {
      _showStep('Platform outage detected (78% failure rate)...');
      await Future.delayed(const Duration(milliseconds: 800));

      _showStep('Rain cross-confirmed by IMD...');
      await Future.delayed(const Duration(milliseconds: 800));

      _showStep('Compound trigger firing...');
      context.read<MockDataService>().triggerExtremeHeat(); // Mock representation

      NotificationService.instance.addDisruptionAlert(
        triggerType: 'Platform + Rain (Compound)',
        zone: 'Velachery Dark Store Zone',
      );

      _showSuccess('Compound payout ₹245 processing. '
          'Check Claims tab — trigger shows compound rate.');

    } catch (e) {
      _showError('Demo error: $e');
    }
  }

  // Muthu — shadow policy nudge
  Future<void> _runMuthu() async {
    _showStep('Simulating disruption for uninsured worker...');
    await Future.delayed(const Duration(seconds: 1));

    _showStep('Calculating missed payout...');
    await Future.delayed(const Duration(seconds: 1));

    // Navigate to policy screen showing shadow nudge
    if (mounted) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 300));
      context.push('/policy?demo=shadow_nudge&missed=680');
    }
  }

  // Fraudster — fraud engine demo
  Future<void> _runFraudster() async {
    final userId = await StorageService.instance.getUserId();
    if (userId == null) return;

    _showStep('Submitting claim with gps_jitter = 0.0 (spoofed GPS)...');
    await Future.delayed(const Duration(seconds: 1));

    _showStep('Isolation Forest scoring...');
    await Future.delayed(const Duration(seconds: 1));

    _showStep('Zero jitter override → FPS score: 87 → RED');
    await Future.delayed(const Duration(seconds: 1));

    // Create a claim that will be flagged
    try {
      context.read<MockDataService>().triggerExtremeHeat(); // Use mock
    } catch (e) {
      // Even if API doesn't support extra fields, show the UI
    }

    _showSuccess(
      'Claim FLAGGED — FPS 87 → RED → Human review queued.\n'
      'Check Claims tab — status shows FLAGGED not APPROVED.\n'
      'Only ₹200 provisional credit released.',
    );
  }

  // Santhosh — trust score + cashback
  Future<void> _runSanthosh() async {
    _showStep('Loading 4 clean weeks history...');
    await Future.delayed(const Duration(seconds: 1));

    _showStep('Sunday settlement: cashback calculation...');
    await Future.delayed(const Duration(seconds: 1));

    _showStep('10% of ₹196 premiums = ₹19.60 cashback credited...');
    await Future.delayed(const Duration(seconds: 1));

    NotificationService.instance.addWalletCredited(amount: 20);

    if (mounted) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 300));
      context.push('/profile?demo=trust_score');
    }
  }

  // Priya — internet blackout
  Future<void> _runPriya() async {
    final userId = await StorageService.instance.getUserId();
    if (userId == null) return;

    _showStep('Ookla: T.Nagar avg speed 0.3 Mbps...');
    await Future.delayed(const Duration(milliseconds: 800));

    _showStep('TRAI registry: Airtel outage logged...');
    await Future.delayed(const Duration(milliseconds: 800));

    _showStep('Dual confirmation → AUTO_TRIGGER...');
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      context.read<MockDataService>().triggerPlatformDowntime();

      NotificationService.instance.addClaimCreated(
        triggerType: 'Internet Zone Blackout',
        amount: 77,
      );

      _showSuccess(
        'Internet blackout claim created.\n'
        'No GPS required — self-validating trigger.\n'
        'Payout ₹77 (70% tranche).',
      );
    } catch (e) {
      _showError('Demo error: $e');
    }
  }

  Future<void> _hardReset() async {
    // Demo Armor: Surgical strike to re-initialize entire app
    if (mounted) {
      RestartWidget.restartApp(context);
    }
  }

void _showStep(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
              color: Color(0xFF1B5E20), size: 48),
            const SizedBox(height: 12),
            Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done',
              style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB71C1C),
      ),
    );
  }
}
