import '../../../../core/utils/map_serializable.dart';
import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/face_recognition_result.dart';

class FaceVerifyResponse extends MapSerializable {
  const FaceVerifyResponse.fromMap(super.data) : super.fromMap();

  bool get match => this['match'] as bool;
  double get distance => (this['distance'] as num).toDouble();

  UserDto? get userDto =>
      getNestedOrNull('user', (data) => UserDto.fromMap(data));

  FaceRecognitionResult toDomain() {
    return FaceRecognitionResult(
      match: match,
      distance: distance,
      user: userDto?.toDomain(),
    );
  }
}
