import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_local_data_source.dart';

class AuthSecureStorageDataSource implements AuthLocalDataSource {
  final FlutterSecureStorage storage;
  static const String _tokenKey = 'auth_token';

  AuthSecureStorageDataSource({required this.storage});

  @override
  Future<String?> getToken() async {
    return await storage.read(key: _tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> clearToken() async {
    await storage.delete(key: _tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
