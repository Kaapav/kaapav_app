import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _api = ApiClient.instance;

  Future<Response> login(String email, String password) {
    return _api.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
      skipAuth: true,
    );
  }

  Future<Response> register(Map<String, dynamic> data) {
    return _api.post('/api/auth/register', data: data, skipAuth: true);
  }

  Future<Response> logout() {
    return _api.post('/api/auth/logout');
  }

  Future<Response> getMe() {
    return _api.get('/api/auth/me');
  }

  Future<Response> refresh() {
    return _api.post('/api/auth/refresh');
  }

  Future<Response> changePassword(Map<String, dynamic> data) {
    return _api.post('/api/auth/change-password', data: data);
  }

  Future<Response> biometricChallenge() {
    return _api.post('/api/auth/biometric/challenge', skipAuth: true);
  }

  Future<Response> biometricVerify(Map<String, dynamic> credential) {
    return _api.post('/api/auth/biometric/verify', data: credential, skipAuth: true);
  }

  Future<Response> biometricRegister(Map<String, dynamic> credential) {
    return _api.post('/api/auth/biometric/register', data: credential);
  }
}