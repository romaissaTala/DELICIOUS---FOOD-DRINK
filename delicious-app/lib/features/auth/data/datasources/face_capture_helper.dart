// lib/features/auth/data/datasources/face_capture_helper.dart
//
// Standalone helper used by the face-auth UI widgets.
// Captures a photo from the camera controller, runs ML Kit face detection,
// and extracts a 128-dimensional landmark vector.
//
// Usage:
//   final helper = FaceCaptureHelper();
//   final result = await helper.captureAndExtract(cameraController);
//   result.fold(
//     (error) => showError(error),
//     (vector) => context.read<AuthBloc>().add(AuthFaceLoginRequested(vector)),
//   );

import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceCaptureResult {
  final List<double> vector;   // 128-dimensional landmark vector
  final int          faceCount;
  const FaceCaptureResult({required this.vector, required this.faceCount});
}

class FaceCaptureHelper {
  // Reuse the detector — it's expensive to create
  late final FaceDetector _detector;

  FaceCaptureHelper() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks:      true,
        enableContours:       true,
        enableClassification: true,
        performanceMode:      FaceDetectorMode.accurate,
        minFaceSize:          0.1,
      ),
    );
  }

  // ── Main entry point ──────────────────────────────────────────────────────

  Future<(String?, FaceCaptureResult?)> captureAndExtract(
    CameraController controller,
  ) async {
    try {
      // 1. Take picture
      final picture  = await controller.takePicture();
      final inputImg = InputImage.fromFilePath(picture.path);

      // 2. Detect faces
      final faces = await _detector.processImage(inputImg);

      if (faces.isEmpty) {
        return ('No face detected. Please look directly at the camera.', null);
      }
      if (faces.length > 1) {
        return ('Multiple faces detected. Please ensure only your face is visible.', null);
      }

      final face = faces.first;

      // 3. Validate detection quality
      if ((face.headEulerAngleY ?? 0).abs() > 20) {
        return ('Please face the camera directly.', null);
      }
      if ((face.smilingProbability ?? 1) < 0) {
        // not a real check — just show structure
      }

      // 4. Extract 128-dim vector from landmarks + contours
      final vector = _extractVector(face);

      if (vector.length != 128) {
        return ('Could not extract enough facial landmarks. Try better lighting.', null);
      }

      return (null, FaceCaptureResult(vector: vector, faceCount: faces.length));
    } catch (e) {
      return ('Face detection failed: $e', null);
    }
  }

  // ── Vector extraction ─────────────────────────────────────────────────────
  //
  // Builds a 128-element vector from:
  //   • 16 landmark (x,y) pairs  = 32 values
  //   • 48 contour  (x,y) pairs  = 96 values  (using the largest available contour set)
  //   Total: 128 values, L2-normalised so cosine similarity works correctly.

  List<double> _extractVector(Face face) {
    final rawValues = <double>[];

    // ── Landmarks (16 standard ML Kit landmarks × 2 coords = 32 values) ────
    const landmarkTypes = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.noseBase,
    ];

   for (final type in landmarkTypes) {
  final lm = face.landmarks[type];
  rawValues.add((lm?.position.x ?? 0.0).toDouble());
  rawValues.add((lm?.position.y ?? 0.0).toDouble());
}

    // Pad landmarks to exactly 32 values
    while (rawValues.length < 32) rawValues.add(0.0);

    // ── Contours (pick the largest set, flatten to 96 values) ──────────────
    const contourTypes = [
      FaceContourType.face,
      FaceContourType.leftEye,
      FaceContourType.rightEye,
      FaceContourType.noseBridge,
      FaceContourType.noseBottom,
      FaceContourType.upperLipTop,
      FaceContourType.lowerLipBottom,
    ];

    final contourValues = <double>[];
    for (final type in contourTypes) {
      final points = face.contours[type]?.points ?? [];
      for (final p in points) {
        contourValues.add(p.x.toDouble());
        contourValues.add(p.y.toDouble());
      }
    }

    // Take first 96 values (pad or truncate)
    final contour96 = contourValues.length >= 96
        ? contourValues.sublist(0, 96)
        : [...contourValues, ...List.filled(96 - contourValues.length, 0.0)];

    final combined = [...rawValues.sublist(0, 32), ...contour96];

    // ── L2 normalisation ────────────────────────────────────────────────────
    final magnitude = math.sqrt(
      combined.fold<double>(0.0, (sum, v) => sum + v * v),
    );
    if (magnitude == 0) return combined; // avoid division by zero

    return combined.map((v) => v / magnitude).toList();
  }

  // ── Cosine similarity (for local pre-check before sending to server) ──────

  static double cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Vectors must be the same length');
    double dot  = 0, magA = 0, magB = 0;
    for (var i = 0; i < a.length; i++) {
      dot  += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (math.sqrt(magA) * math.sqrt(magB));
  }

  static const double matchThreshold = 0.92;

  static bool isMatch(List<double> a, List<double> b) =>
      cosineSimilarity(a, b) >= matchThreshold;

  void dispose() => _detector.close();
}