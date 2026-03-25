import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/router/app_router.dart';
import '../../services/mock_data_service.dart';

// ─── Local Palette ────────────────────────────────────────────────────────────
const _bgScreen   = Color(0xFFF0F4F0);
const _green      = Color(0xFF2E7D32);
const _primary    = Color(0xFF1A1A2E);
const _grey       = Color(0xFF6B7280);
const _cardWhite  = Colors.white;

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockData = Provider.of<MockDataService>(context);
    final worker = mockData.worker;

    return Scaffold(
      backgroundColor: _bgScreen,
      // Stack allows us to place the scrollable content and floating elements overlapping
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140), // Space for sticky bottom button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Margin top
                Text(
                  "You're all set, ${worker.name}!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Illustration Container
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: _cardWhite,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Placeholder for the delivery worker illustration
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(
                            Icons.delivery_dining,
                            size: 80,
                            color: Color(0xFF2D6A2D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Confirmation Details Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000), // rgba(0,0,0,0.06) roughly
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Confirmation Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Your zone: ',
                        value: '${worker.zone}, ${worker.city}',
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Your platform: ',
                        value: worker.platform,
                      ),
                      const SizedBox(height: 16),
                      const _DetailRow(
                        label: 'Coverage starts: ',
                        value: 'Monday',
                      ),
                      const SizedBox(height: 16),
                      // ISS Score reveal card
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                        ),
                        child: Column(
                          children: [
                            const Text('Your Income Stability Score',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('62', style: TextStyle(
                                    fontSize: 48, fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF9800))),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF9800),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('AMBER',
                                          style: TextStyle(color: Colors.white,
                                              fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Standard Shield recommended',
                                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Bottom Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final box = Hive.box('appData');
                        box.put('onboardingComplete', true);
                        
                        // Navigate to /dashboard and clear back stack natively
                        context.go(AppRoutes.dashboard);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Start Protecting My Income',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Floating Help Button overlapping slightly
                  Positioned(
                    right: -8, // Adjust to overlap edge slightly
                    bottom: -16, // Adjust to overlap edge slightly
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x29000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 24),
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, height: 1.4),
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: _grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
