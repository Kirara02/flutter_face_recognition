import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

part 'face_recognition_state.freezed.dart';

@freezed
abstract class FaceRecognitionState with _$FaceRecognitionState {
  const factory FaceRecognitionState({
    @Default(false) bool isInitializing,
    @Default(false) bool isProcessing,
    @Default([]) List<Face> faces,
    String? error,
    @Default(false) bool success,
  }) = _FaceRecognitionState;
}
