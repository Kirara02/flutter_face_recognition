import '../../../../../core/utils/map_serializable.dart';

class LoginRequest extends Serializable {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  @override
  Map<String, dynamic> toMap() {
    return {'username': username, 'password': password};
  }
}
