import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../../../auth/data/datasources/face_capture_helper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class FaceSetupPage extends StatefulWidget {
  const FaceSetupPage({super.key});

  @override
  State<FaceSetupPage> createState() => _FaceSetupPageState();
}

class _FaceSetupPageState extends State<FaceSetupPage> {
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
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _setupFaceAuth() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final result = await _faceHelper.captureAndExtract(_cameraController!);
    
    if (mounted) {
      if (result.$1 != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.$1!), backgroundColor: Colors.red),
        );
      } else if (result.$2 != null) {
        context.read<AuthBloc>().add(AuthFaceVectorSaveRequested(result.$2!.vector));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face authentication enabled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
    setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFaceVectorSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Face authentication enabled!')),
            );
            Navigator.pop(context);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isInitialized
                    ? Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Face Recognition Setup',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Look directly at the camera. Make sure your face is well lit and visible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _setupFaceAuth,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.face),
                    label: Text(_isProcessing ? 'Processing...' : 'Enable Face Login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}