// lib/features/auth/data/datasources/auth_remote_datasource.dart
//
// Handles all network calls for authentication.
// Throws typed exceptions that AuthRepositoryImpl catches and maps to Failures.

import 'package:dio/dio.dart';

import '../models/auth_models.dart';

// ── Contract ──────────────────────────────────────────────────────────────────

abstract class AuthRemoteDataSource {
  Future<AuthResponse> register(RegisterRequest request);
  Future<AuthResponse> login(LoginRequest request);
  Future<void>         logout(String refreshToken);
  Future<AuthResponse> refreshToken(String refreshToken);
  Future<void>         saveFaceVector(SaveFaceVectorRequest request);

  /// Server-side face auth: sends the input vector to the backend,
  /// which computes cosine similarity against the stored vector and
  /// returns a JWT pair if similarity >= 0.92.
  Future<AuthResponse> authenticateWithFace(FaceAuthRequest request);

  Future<UserModel>    getProfile();
}

// ── Implementation ────────────────────────────────────────────────────────────

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Unwraps the API envelope: { success, data: { ... }, message }
  Map<String, dynamic> _unwrap(Response response) {
    final body = response.data as Map<String, dynamic>;
    if (body['success'] == true && body['data'] != null) {
      return body['data'] as Map<String, dynamic>;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: (body['message'] as String?) ?? 'Unknown server error',
    );
  }

  // ── Register ─────────────────────────────────────────────────────────────

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      '/auth/register',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(_unwrap(response));
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(_unwrap(response));
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout(String refreshToken) async {
    await _dio.delete(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResponse.fromJson(_unwrap(response));
  }

  // ── Save face vector ──────────────────────────────────────────────────────
  // Called once after the user sets up face login in their profile settings.
  // The 128-element vector produced by ML Kit is sent and stored server-side.

  @override
  Future<void> saveFaceVector(SaveFaceVectorRequest request) async {
    await _dio.post(
      '/auth/face/save',
      data: request.toJson(),
    );
  }

  // ── Face vector auth ──────────────────────────────────────────────────────
  // At login the user's face is captured, the vector extracted, and sent here.
  // The backend compares it with the stored vector using cosine similarity.
  // Similarity >= 0.92  →  returns JWT pair
  // Similarity <  0.92  →  returns 401

  @override
  Future<AuthResponse> authenticateWithFace(FaceAuthRequest request) async {
    final response = await _dio.post(
      '/auth/face/login',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(_unwrap(response));
  }

  // ── Get profile ───────────────────────────────────────────────────────────

  @override
  Future<UserModel> getProfile() async {
    final response = await _dio.get('/auth/me');
    final data     = _unwrap(response);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }
}