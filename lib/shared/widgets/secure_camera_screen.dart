import 'dart:convert';
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

class _SecureCameraScreenState extends State<SecureCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInit = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
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
        // Enforce front camera for face liveness
        selectedCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first, // fallback if front not found
        );
      } else {
        // Enforce back camera for Aadhaar/Claims
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.instructions,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: _errorMsg != null 
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))))
                : !_isInit || _controller == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _buildCameraPreview(),
            ),
            
            const SizedBox(height: 30),
            _buildCaptureButton(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
               width: _controller!.value.previewSize?.height ?? 1,
               height: _controller!.value.previewSize?.width ?? 1,
               child: CameraPreview(_controller!),
            ),
          ),
          
          // Overlays based on mode
          if (widget.mode == CameraMode.kycFace)
             _buildCircularOverlay()
          else if (widget.mode == CameraMode.kycAadhaar)
             _buildDocumentOverlay()
        ],
      ),
    );
  }

  Widget _buildCircularOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
        ),
      ),
    );
  }
  
  Widget _buildDocumentOverlay() {
    return Center(
      child: Container(
        width: 320,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
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
          border: Border.all(color: Colors.green, width: 4),
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
