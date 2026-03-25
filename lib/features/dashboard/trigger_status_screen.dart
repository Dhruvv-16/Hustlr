import 'package:flutter/material.dart';
import '../../core/constants/colors.dart' as app_colors;
import '../../data/mock_data.dart';

class TriggerStatusScreen extends StatelessWidget {
  const TriggerStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        title: const Text('Live Trigger Monitoring'),
        backgroundColor: app_colors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Auto-monitoring ${MockData.userZone} every 15 minutes',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: MockData.liveStatus.length,
              itemBuilder: (context, index) => _buildTriggerDetailCard(MockData.liveStatus[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Text(
              'All triggers monitored automatically every 15 minutes.\nYou never need to check this — Hustlr notifies you by Sunday 11 PM.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: app_colors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerDetailCard(Map<String, dynamic> trigger) {
    final bool isElevated = trigger['status'] == 'ELEVATED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isElevated ? Border.all(color: app_colors.amber, width: 2) : Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(trigger['emoji'], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(trigger['trigger'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              _statusBadge(trigger['status']),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Current reading', trigger['reading']),
          _infoRow('Trigger threshold', trigger['threshold']),
          _infoRow('Data source', trigger['source']),
          _infoRow('Last checked', '2 minutes ago'),
          _infoRow('If triggered', trigger['rate']),
          
          if (isElevated) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: app_colors.lightAmber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: app_colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Getting close to threshold. If temperature exceeds 43°C during your shift, ₹40/hr activates automatically.',
                      style: TextStyle(color: Color(0xFFE65100), fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final bool isElevated = status == 'ELEVATED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isElevated ? app_colors.lightAmber : app_colors.lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isElevated ? const Color(0xFFE65100) : app_colors.primaryGreen,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: app_colors.textSecondary, fontSize: 13))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(color: app_colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
