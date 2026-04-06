import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'face_detector_service.g.dart';

class FaceDetectorService {
  late FaceDetector _faceDetector;

  FaceDetectorService() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  void dispose() {
    _faceDetector.close();
  }
}

@Riverpod(keepAlive: true)
FaceDetectorService faceDetectorService(Ref ref) {
  final service = FaceDetectorService();
  ref.onDispose(service.dispose);
  return service;
}
