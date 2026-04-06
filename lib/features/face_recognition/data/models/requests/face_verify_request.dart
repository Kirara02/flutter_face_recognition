import '../../../../../core/utils/map_serializable.dart';

class FaceVerifyRequest extends Serializable {
  final List<double> embedding;

  const FaceVerifyRequest({required this.embedding});

  @override
  Map<String, dynamic> toMap() => {
        'embedding': embedding,
      };
}
