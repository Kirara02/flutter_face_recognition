import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../auth/domain/entities/user.dart';

part 'face_recognition_result.freezed.dart';

@freezed
abstract class FaceRecognitionResult with _$FaceRecognitionResult {
  const factory FaceRecognitionResult({
    required bool match,
    required double distance,
    User? user,
  }) = _FaceRecognitionResult;
}
