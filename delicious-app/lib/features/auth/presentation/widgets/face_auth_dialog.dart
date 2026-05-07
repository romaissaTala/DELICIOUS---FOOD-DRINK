import 'package:Delicious_App/features/auth/data/datasources/face_capture_helper.dart';
import 'package:Delicious_App/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class FaceAuthDialog extends StatefulWidget {
  final CameraDescription camera;
  const FaceAuthDialog({super.key, required this.camera});

  @override
  State<FaceAuthDialog> createState() => _FaceAuthDialogState();
}

class _FaceAuthDialogState extends State<FaceAuthDialog> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  final FaceCaptureHelper _faceHelper = FaceCaptureHelper();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _captureAndAuthenticate() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final result = await _faceHelper.captureAndExtract(_cameraController!);
    
    if (mounted) {
      if (result.$1 != null) {
        // Error occurred
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.$1!), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      } else if (result.$2 != null) {
        // Success - authenticate with face vector
        context.read<AuthBloc>().add(AuthFaceLoginRequested(result.$2!.vector));
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Face Recognition Login',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Look directly at the camera',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Camera Preview
            if (_isInitialized)
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CameraPreview(_cameraController!),
                ),
              )
            else
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _captureAndAuthenticate,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera),
              label: Text(_isProcessing ? 'Processing...' : 'Capture & Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}