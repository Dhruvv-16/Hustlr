import 'package:flutter/material.dart';
import '../../data/mock_data.dart';

class TriggerStatusScreen extends StatelessWidget {
  const TriggerStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        title: Text('Live Trigger Monitoring', style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Icon(Icons.radar_rounded, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Auto-monitoring ${MockData.userZone} every 15 mins',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: MockData.liveStatus.length,
              itemBuilder: (context, index) => _buildTriggerDetailCard(MockData.liveStatus[index], theme, isDark),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.bolt_rounded, color: theme.colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'All triggers monitored automatically. You never need to check this — Hustlr notifies you by Sunday 11 PM.',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6), height: 1.5, fontWeight: FontWeight.w600),
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

  Widget _buildTriggerDetailCard(Map<String, dynamic> trigger, ThemeData theme, bool isDark) {
    final bool isElevated = trigger['status'] == 'ELEVATED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isElevated ? Colors.orange : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
          width: isElevated ? 2 : 1.5,
        ),
        boxShadow: isDark ? [] : [
           BoxShadow(color: isElevated ? Colors.orange.withOpacity(0.1) : const Color(0x05000000), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: (isElevated ? Colors.orange : theme.colorScheme.primary).withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(trigger['emoji'], style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 14),
                  Text(trigger['trigger'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: theme.colorScheme.onSurface, letterSpacing: -0.3)),
                ],
              ),
              _statusBadge(trigger['status'], theme, isDark),
            ],
          ),
          const SizedBox(height: 20),
          _infoRow('Current reading', trigger['reading'], theme),
          _infoRow('Trigger threshold', trigger['threshold'], theme),
          _infoRow('Data source', trigger['source'], theme),
          _infoRow('Last checked', '2 minutes ago', theme),
          _infoRow('If triggered', trigger['rate'], theme, true),
          
          if (isElevated) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Getting close to threshold. If temperature exceeds 43°C during your shift, ₹40/hr activates automatically.',
                      style: TextStyle(color: Colors.orange, fontSize: 13, height: 1.4, fontWeight: FontWeight.w700),
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

  Widget _statusBadge(String status, ThemeData theme, bool isDark) {
    final bool isElevated = status == 'ELEVATED';
    final color = isElevated ? Colors.orange : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme, [bool isHighlight = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w700))),
          Expanded(flex: 3, child: Text(
            value,
            style: TextStyle(
              color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
            ),
          )),
        ],
      ),
    );
  }
}
