import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/safe_api_call.dart';
import '../../../../core/base/result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/face_models.dart';
import '../models/requests/face_register_request.dart';
import '../models/requests/face_verify_request.dart';

part 'face_remote_datasource.g.dart';

abstract class FaceRemoteDataSource {
  Future<Result<void>> registerFace(FaceRegisterRequest request);
  Future<Result<FaceVerifyResponse>> verifyFace(FaceVerifyRequest request);
}

class FaceRemoteDataSourceImpl implements FaceRemoteDataSource {
  final Dio _dio;

  FaceRemoteDataSourceImpl(this._dio);

  @override
  Future<Result<void>> registerFace(FaceRegisterRequest request) async {
    return safeApiCall(
      () => _dio.post('/api/faces/register', data: request.toMap()),
      mapper: (data) {},
    );
  }

  @override
  Future<Result<FaceVerifyResponse>> verifyFace(
    FaceVerifyRequest request,
  ) async {
    return safeApiCall(
      () => _dio.post('/api/faces/verify', data: request.toMap()),
      mapper: (data) =>
          FaceVerifyResponse.fromMap(data as Map<String, dynamic>),
    );
  }
}

@riverpod
FaceRemoteDataSource faceRemoteDataSource(Ref ref) {
  return FaceRemoteDataSourceImpl(ref.watch(dioProvider));
}
