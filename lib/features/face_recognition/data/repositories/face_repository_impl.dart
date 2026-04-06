import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/base/result.dart';
import '../../domain/entities/face_recognition_result.dart';
import '../../domain/repositories/face_repository.dart';
import '../datasources/face_remote_datasource.dart';
import '../models/requests/face_register_request.dart';
import '../models/requests/face_verify_request.dart';

part 'face_repository_impl.g.dart';

@riverpod
IFaceRepository faceRepository(Ref ref) {
  return FaceRepositoryImpl(ref.watch(faceRemoteDataSourceProvider));
}

class FaceRepositoryImpl implements IFaceRepository {
  final FaceRemoteDataSource _remoteDataSource;

  FaceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<void>> registerFace(FaceRegisterRequest request) {
    return _remoteDataSource.registerFace(request);
  }

  @override
  Future<Result<FaceRecognitionResult>> verifyFace(
    FaceVerifyRequest request,
  ) async {
    final result = await _remoteDataSource.verifyFace(request);
    return result.when(
      success: (response, message) => Result.success(response.toDomain()),
      failure: (error, stackTrace) => Result.failure(error, stackTrace),
    );
  }
}
