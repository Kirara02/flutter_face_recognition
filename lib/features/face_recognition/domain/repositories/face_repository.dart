import '../../../../core/base/result.dart';
import '../../data/models/requests/face_register_request.dart';
import '../../data/models/requests/face_verify_request.dart';
import '../entities/face_recognition_result.dart';

abstract class IFaceRepository {
  Future<Result<void>> registerFace(FaceRegisterRequest request);
  Future<Result<FaceRecognitionResult>> verifyFace(FaceVerifyRequest request);
}
