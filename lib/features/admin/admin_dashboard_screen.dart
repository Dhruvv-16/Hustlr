import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 64, color: primaryGreen),
            SizedBox(height: 16),
            Text('Admin', style: AppTextStyles.heading1),
            SizedBox(height: 8),
            Text('Screen stub — implement in iteration 8',
                style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
