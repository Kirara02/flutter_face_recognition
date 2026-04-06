import '../../../../../../core/utils/map_serializable.dart';

class FaceRegisterRequest extends Serializable {
  final int userId;
  final List<double> embedding;

  const FaceRegisterRequest({
    required this.userId,
    required this.embedding,
  });

  @override
  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'embedding': embedding,
      };
}
