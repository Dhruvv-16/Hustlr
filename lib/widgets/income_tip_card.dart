import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IncomeTipCard extends StatefulWidget {
  const IncomeTipCard({super.key});

  @override
  State<IncomeTipCard> createState() => _IncomeTipCardState();
}

class _IncomeTipCardState extends State<IncomeTipCard> {
  bool _isVisible = false;
  int _tipIndex = 0;
  int _sessionCount = 0;

  static const List<Map<String, dynamic>> _tips = [
    {
      'icon': Icons.access_time_rounded,
      'title': 'Earn more during peak hours',
      'body': 'Morning 8–11 AM and evening 5–9 PM have the highest order density in your zone. Consistent peak-hour deliveries build a stronger income history.',
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Stay covered through monsoon season',
      'body': 'Chennai\'s northeast monsoon runs October to December. Workers with active coverage during the full season receive payouts automatically when rain thresholds are crossed.',
    },
    {
      'icon': Icons.location_on_rounded,
      'title': 'Stay close to your dark store',
      'body': 'Orders are assigned based on proximity to the Zepto dark store. Staying within your delivery radius means faster assignment and more deliveries per shift.',
    },
    {
      'icon': Icons.bolt_rounded,
      'title': 'Activate coverage before the week starts',
      'body': 'Coverage activates on Monday and covers disruptions through Sunday. Activating mid-week means pro-rata coverage only — activate Monday morning for full protection.',
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Consistent weeks build a stronger profile',
      'body': 'Workers who maintain active coverage across multiple consecutive weeks are eligible for the claim-free cashback on Elite Shield.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkShouldShowTip();
  }

  Future<void> _checkShouldShowTip() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get session count and increment
    _sessionCount = prefs.getInt('session_count') ?? 0;
    _sessionCount++;
    await prefs.setInt('session_count', _sessionCount);
    
    // Only show tip 1 in every 3 app opens
    if (_sessionCount % 3 != 1) {
      return;
    }
    
    // Check if last tip was shown more than 48 hours ago
    final lastTipShown = prefs.getInt('last_tip_shown') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const fortyEightHours = 48 * 60 * 60 * 1000; // 48 hours in milliseconds
    
    if (now - lastTipShown < fortyEightHours) {
      return;
    }
    
    // Get tip index (cycle through tips)
    _tipIndex = prefs.getInt('tip_index') ?? 0;
    
    setState(() {
      _isVisible = true;
    });
  }

  Future<void> _dismissTip() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save timestamp and increment tip index
    await prefs.setInt('last_tip_shown', DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('tip_index', (_tipIndex + 1) % _tips.length);
    
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final tip = _tips[_tipIndex];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF2E7D32), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tip['icon'] as IconData,
                  color: const Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'INCOME TIP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _dismissTip,
                child: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tip['title'] as String,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D1B0F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip['body'] as String,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF4A6741),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
