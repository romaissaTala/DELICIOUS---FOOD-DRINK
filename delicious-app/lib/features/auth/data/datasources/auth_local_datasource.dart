// lib/features/auth/data/datasources/auth_local_datasource.dart
//
// Persists auth tokens and user profile on the device.
//   • FlutterSecureStorage  →  tokens (AES-encrypted on Android, Keychain on iOS)
//   • Hive box              →  user profile JSON (fast, typed, offline-first)

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../models/auth_models.dart';

// ── Storage keys ─────────────────────────────────────────────────────────────

abstract class _K {
  static const accessToken  = 'access_token';
  static const refreshToken = 'refresh_token';
  static const cachedUser   = 'cached_user';
}

// ── Contract ──────────────────────────────────────────────────────────────────

abstract class AuthLocalDataSource {
  Future<void>      saveTokens({required String accessToken, required String refreshToken});
  Future<String?>   getAccessToken();
  Future<String?>   getRefreshToken();
  Future<void>      clearTokens();

  Future<void>      saveUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void>      clearUser();
}

// ── Implementation ────────────────────────────────────────────────────────────

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final Box                  _userBox;

  const AuthLocalDataSourceImpl({
    required FlutterSecureStorage secureStorage,
    required Box userBox,
  })  : _secureStorage = secureStorage,
        _userBox       = userBox;

  // ── Tokens ────────────────────────────────────────────────────────────────

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _K.accessToken,  value: accessToken),
      _secureStorage.write(key: _K.refreshToken, value: refreshToken),
    ]);
  }

  @override
  Future<String?> getAccessToken() =>
      _secureStorage.read(key: _K.accessToken);

  @override
  Future<String?> getRefreshToken() =>
      _secureStorage.read(key: _K.refreshToken);

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _K.accessToken),
      _secureStorage.delete(key: _K.refreshToken),
    ]);
  }

  // ── User ──────────────────────────────────────────────────────────────────

  @override
  Future<void> saveUser(UserModel user) async {
    await _userBox.put(_K.cachedUser, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final raw = _userBox.get(_K.cachedUser) as String?;
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clearUser() async {
    await _userBox.delete(_K.cachedUser);
  }
}