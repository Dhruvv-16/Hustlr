import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/demo_state_service.dart';
import '../../../services/app_events.dart';
import '../../../core/router/app_router.dart';

void showDemoPanel(BuildContext context, {VoidCallback? onSubmit}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: const DemoControlPanel(),
      );
    },
  ).then((_) {
    if (onSubmit != null) onSubmit();
  });
}

class DemoControlPanel extends StatefulWidget {
  const DemoControlPanel({super.key});

  @override
  State<DemoControlPanel> createState() => _DemoControlPanelState();
}

class _DemoControlPanelState extends State<DemoControlPanel> {
  bool _isTriggering = false;
  String? _lastResult;

  Future<void> _triggerDisruption(String type) async {
    if (_isTriggering) return;
    setState(() { _isTriggering = true; _lastResult = null; });

    final userId = await StorageService.instance.getUserId() ?? 'mock-karthik-001';
    
    final payouts = {
      'rain':     120,
      'heat':     130,
      'platform': 140,
    };
    final names = {
      'rain':     'Heavy Rain',
      'heat':     'Extreme Heat',
      'platform': 'Platform Downtime',
    };
    
    final grossPayout = payouts[type] ?? 120;
    final tranche1 = (grossPayout * 0.70).round();
    final tranche2 = grossPayout - tranche1;
    
    try {
      // Try real API first
      final res = await ApiService.instance.createClaim(
        userId:        userId,
        triggerType:   type == 'platform' ? 'platform_downtime' : (type == 'rain' ? 'rain_heavy' : 'extreme_heat'),
        severity:      0.85,
        durationHours: 3.0,
      );
      
      if (res['claim'] != null) {
        // Real claim created — fire events
        AppEvents.instance.claimUpdated();
        AppEvents.instance.walletUpdated();
        
        setState(() {
          _isTriggering = false;
          _lastResult = '✅ ${names[type]} — ₹$tranche1 credited (live API)';
        });
        return;
      }
    } catch (e) {
      print('[Demo] API failed: $e — using mock');
    }
    
    // Mock fallback — directly update local state
    final mockClaim = {
      'id':          'CLM_DEMO_${DateTime.now().millisecondsSinceEpoch}',
      'trigger_type': type == 'platform' ? 'platform_downtime' : (type == 'rain' ? 'rain_heavy' : 'extreme_heat'),
      'display_name': names[type],
      'status':       'PENDING',
      'gross_payout': grossPayout,
      'tranche1_amount': tranche1,
      'tranche2_amount': tranche2,
      'fraud_score':  14,
      'fraud_status': 'CLEAN',
      'created_at':   DateTime.now().toIso8601String(),
      '_mock':        true,
    };
    
    // Add to local claims store
    DemoStateService.instance.addClaim(mockClaim);
    DemoStateService.instance.creditWallet(tranche1, '${names[type]} Payout (70%)');
    
    // Fire app events — dashboard + wallet + claims all refresh
    AppEvents.instance.claimUpdated();
    AppEvents.instance.walletUpdated();
    
    // Auto-approve after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      DemoStateService.instance.approveClaim(mockClaim['id'] as String);
      AppEvents.instance.claimUpdated();
    });
    
    setState(() {
      _isTriggering = false;
      _lastResult = '✅ ${names[type]} — ₹$tranche1 credited';
    });
    
    // Notify user
    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${names[type]} triggered — ₹$tranche1 to wallet'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetDemo() async {
    await DemoStateService.instance.reset();
    AppEvents.instance.claimUpdated();
    AppEvents.instance.walletUpdated();
    AppEvents.instance.policyUpdated();
    
    setState(() => _lastResult = '🔄 Demo state reset');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo reset — all state cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFF10B981), width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡ Demo Controls',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Simulates real parametric triggers',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          
          _triggerButton('🌧  Trigger Rain Disruption',
            '72mm · IMD threshold crossed', 'rain', const Color(0xFF3B82F6)),
          const SizedBox(height: 10),
          _triggerButton('🌡  Trigger Extreme Heat',
            '43°C · Heatwave confirmed', 'heat', const Color(0xFFEF4444)),
          const SizedBox(height: 10),
          _triggerButton('📵  Trigger Platform Downtime',
            'Order failure rate > 60%', 'platform', const Color(0xFFF59E0B)),
          
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Text(_lastResult!,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 13)),
            ),
          ],
          
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.analytics, color: Color(0xFF10B981), size: 16),
            label: const Text('View Live ML Models',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              context.push('/ml-live');
            },
          ),
          TextButton(
            onPressed: _resetDemo,
            child: const Text('Reset Demo State',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _triggerButton(String title, String subtitle, String type, Color color) {
    return GestureDetector(
      onTap: _isTriggering ? null : () => _triggerDisruption(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            )),
            if (_isTriggering)
              SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: color, strokeWidth: 2))
            else
              Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}
