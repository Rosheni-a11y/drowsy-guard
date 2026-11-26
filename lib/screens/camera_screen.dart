import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/face_detector_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  CameraDescription? _camera;
  bool _isReady = false;
  String _error = '';

  final FaceDetectorService _detectorService = FaceDetectorService();

  // Debug info to show on screen
  String _debugText = 'Waiting for face...';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _camera!,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isReady = true);
        _startDetection();
      }
    } catch (e) {
      setState(() => _error = 'Camera error: $e');
    }
  }

  void _startDetection() {
    _controller!.startImageStream((image) {
      _detectorService.processImage(image, _camera!).then((faces) {
        if (!mounted) return;

        if (faces.isEmpty) {
          setState(() => _debugText = 'No face detected');
          return;
        }

        final face = faces.first;
        final leftEye = face.leftEyeOpenProbability ?? -1;
        final rightEye = face.rightEyeOpenProbability ?? -1;
        final headX = face.headEulerAngleX ?? 0; // Up/down tilt
        final headY = face.headEulerAngleY ?? 0; // Left/right turn
        final headZ = face.headEulerAngleZ ?? 0; // Tilt sideways

        setState(() {
          _debugText = 'Left eye: ${leftEye.toStringAsFixed(2)}\n'
              'Right eye: ${rightEye.toStringAsFixed(2)}\n'
              'Head X (tilt): ${headX.toStringAsFixed(1)}\n'
              'Head Y (turn): ${headY.toStringAsFixed(1)}\n'
              'Head Z (roll): ${headZ.toStringAsFixed(1)}';
        });
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text(_error, style: const TextStyle(color: Colors.white))),
      );
    }

    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Drowsy Guard'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          // Debug text overlay
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugText,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
