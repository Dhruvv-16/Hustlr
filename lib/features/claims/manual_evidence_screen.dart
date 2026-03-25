import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart' as app_colors;

class ManualEvidenceScreen extends StatelessWidget {
  final String disruptionType;

  const ManualEvidenceScreen({super.key, required this.disruptionType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      appBar: AppBar(
        backgroundColor: app_colors.primaryGreen,
        title: const Text('Report a Disruption',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              disruptionType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: app_colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (disruptionType == 'Road Blocked / Accident') ...[
              _buildCameraButton('Take photo of blockage', subtitle: 'App will GPS-stamp and timestamp automatically'),
              const SizedBox(height: 16),
              _buildGPSPreview(),
              const SizedBox(height: 24),
              _buildSubmitButton(context, 'Confirm my location', isOutlined: true),
            ] else if (disruptionType == 'Heavy Traffic Congestion') ...[
              _buildCameraButton('Take photo of blocked road', subtitle: 'App will GPS-stamp and timestamp automatically'),
              const SizedBox(height: 16),
              _buildGPSPreview(),
              const SizedBox(height: 24),
              _buildSubmitButton(context, 'Confirm my location', isOutlined: true),
            ] else if (disruptionType == 'Dark Store / Hub Closed') ...[
              _buildCameraButton('Take photo of closed hub'),
              const SizedBox(height: 16),
              _buildUploadPlaceholder('Upload Zepto screenshot (no orders showing)'),
              const SizedBox(height: 24),
              _buildSubmitButton(context, 'Submit Claim →'),
            ] else if (disruptionType == 'Internet Outage') ...[
              _buildSignalBars(),
              const SizedBox(height: 24),
              _buildSubmitButton(context, 'Confirm I cannot work', subtitle: 'No photo needed — verified by network data'),
            ] else ...[
              _buildCameraButton('Take one photo'),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Describe the disruption (max 100 characters)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLength: 100,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildSubmitButton(context, 'Submit Claim →'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraButton(String text, {String? subtitle}) {
    return InkWell(
      onTap: () {}, // Mock camera open
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: app_colors.primaryGreen.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: app_colors.primaryGreen, size: 64),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: app_colors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: app_colors.textSecondary, fontSize: 12)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(String text) {
    return InkWell(
      onTap: () {}, // Mock file picker
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, color: app_colors.primaryGreen, size: 32),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: app_colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildGPSPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.location_on, color: app_colors.primaryGreen, size: 32),
          SizedBox(height: 8),
          Text('Your location: Adyar, Chennai', style: TextStyle(color: app_colors.textPrimary, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Captured automatically', style: TextStyle(color: app_colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSignalBars() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 12, height: 20, margin: const EdgeInsets.symmetric(horizontal: 2), color: app_colors.errorRed),
              Container(width: 12, height: 35, margin: const EdgeInsets.symmetric(horizontal: 2), color: const Color(0xFFE5E7EB)),
              Container(width: 12, height: 50, margin: const EdgeInsets.symmetric(horizontal: 2), color: const Color(0xFFE5E7EB)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Current signal: Weak (1 bar)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Zone average: 45 Mbps normally', style: TextStyle(color: app_colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, String text, {bool isOutlined = false, String? subtitle}) {
    Widget btn;
    if (isOutlined) {
      btn = OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: app_colors.primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => context.push('/claims/submitted'),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: app_colors.primaryGreen)),
      );
    } else {
      btn = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: app_colors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => context.push('/claims/submitted'),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      );
    }

    if (subtitle == null) return SizedBox(width: double.infinity, child: btn);
    
    return Column(
      children: [
        SizedBox(width: double.infinity, child: btn),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: app_colors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

