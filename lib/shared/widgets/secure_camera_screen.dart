import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

enum CameraMode {
  kycFace,    // strictly front camera, requires clear face matching
  kycAadhaar, // back camera, macro focus for document scanning
  claim,      // back camera, general scene capture
}

class SecureCameraScreen extends StatefulWidget {
  final CameraMode mode;
  final String title;
  final String instructions;

  const SecureCameraScreen({
    super.key,
    required this.mode,
    required this.title,
    required this.instructions,
  });

  @override
  State<SecureCameraScreen> createState() => _SecureCameraScreenState();
}

class _SecureCameraScreenState extends State<SecureCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInit = false;
  String? _errorMsg;
  late AnimationController _borderAnim;
  late Animation<double> _borderOpacity;

  @override
  void initState() {
    super.initState();
    _borderAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _borderOpacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _borderAnim, curve: Curves.easeInOut),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMsg = 'No cameras available on this device');
        return;
      }

      CameraDescription? selectedCamera;

      if (widget.mode == CameraMode.kycFace) {
        selectedCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
      } else {
        selectedCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInit = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Camera access denied or failed: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _borderAnim.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();
      final base64String = base64Encode(bytes);

      if (mounted) {
        Navigator.pop(context, {
          'base64': base64String,
          'path': photo.path,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance
                ],
              ),
            ),

            // Camera / error area
            Expanded(
              child: _errorMsg != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _errorMsg!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    )
                  : !_isInit || _controller == null
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                      : _buildCameraPreview(),
            ),

            // Instructions strip at bottom
            if (_isInit && _errorMsg == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Text(
                  widget.mode == CameraMode.kycFace
                      ? 'Centre your face fully within the oval.\nMake sure eyes, nose and chin are visible.'
                      : widget.instructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 16),
            _buildCaptureButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewW = constraints.maxWidth;
        final previewH = constraints.maxHeight;
        // Oval guide: 70% width, 55% height → taller-than-wide face oval
        final ovalW = previewW * 0.72;
        final ovalH = previewH * 0.58;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen camera feed
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize?.height ?? 1,
                height: _controller!.value.previewSize?.width ?? 1,
                child: CameraPreview(_controller!),
              ),
            ),

            if (widget.mode == CameraMode.kycFace) ...[
              // Dark cutout overlay — draws dark everywhere except the oval
              CustomPaint(
                painter: _OvalCutoutPainter(
                  ovalWidth: ovalW,
                  ovalHeight: ovalH,
                ),
                child: const SizedBox.expand(),
              ),

              // Animated oval border ring
              AnimatedBuilder(
                animation: _borderOpacity,
                builder: (_, __) => Center(
                  child: Container(
                    width: ovalW,
                    height: ovalH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ovalW / 2),
                      border: Border.all(
                        color: const Color(0xFF4CAF50)
                            .withOpacity(_borderOpacity.value),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),

              // "Position face here" label inside oval
              Align(
                alignment: const Alignment(0, 0.85),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Fill your face in the oval',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ] else if (widget.mode == CameraMode.kycAadhaar)
              _buildDocumentOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildDocumentOverlay() {
    return Center(
      child: Container(
        width: 320,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _capture,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4CAF50), width: 4),
          color: Colors.transparent,
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a dark semi-transparent overlay with an oval cutout.
/// The cutout reveals the camera feed clearly, dimming everything outside.
class _OvalCutoutPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;

  _OvalCutoutPainter({required this.ovalWidth, required this.ovalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final oval = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy),
        width: ovalWidth,
        height: ovalHeight,
      ));

    final cutout = Path.combine(PathOperation.difference, path, oval);

    canvas.drawPath(
      cutout,
      Paint()..color = Colors.black.withOpacity(0.62),
    );
  }

  @override
  bool shouldRepaint(_OvalCutoutPainter oldDelegate) =>
      oldDelegate.ovalWidth != ovalWidth || oldDelegate.ovalHeight != ovalHeight;
}
