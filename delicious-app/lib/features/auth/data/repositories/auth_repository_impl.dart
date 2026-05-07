// lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Implements every method of the domain AuthRepository.
// Responsibilities:
//   1. Call the remote datasource and persist tokens + user locally.
//   2. Map DioException / PlatformException → typed domain Failures.
//   3. Orchestrate biometric (local_auth) and face-vector (ML Kit) login flows.
//   4. Never expose Dio, Hive, or FlutterSecureStorage to the domain/presentation layers.

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final LocalAuthentication _localAuth;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required LocalAuthentication localAuth,
  })  : _remote = remote,
        _local = local,
        _localAuth = localAuth;

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Persists tokens + user model after any successful auth call.
  Future<void> _persistSession(AuthResponse resp) async {
    await Future.wait([
      _local.saveTokens(
        accessToken: resp.accessToken,
        refreshToken: resp.refreshToken,
      ),
      _local.saveUser(resp.user),
    ]);
  }

  /// Wraps a remote call, catches DioException, and maps it to a Failure.
  Future<Either<Failure, T>> _tryCatch<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = (e.response?.data as Map?)?['message'] as String? ??
        e.message ??
        'Unknown error';

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkFailure('No internet connection. Check your network.');
    }
    switch (statusCode) {
      case 400:
        return ValidationFailure(message);
      case 401:
        return UnauthorizedFailure(message);
      case 409:
        return ValidationFailure(message); // duplicate email
      default:
        return ServerFailure(message);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    return _tryCatch(() async {
      final resp = await _remote.register(
        RegisterRequest(
            email: email, password: password, name: name, phone: phone),
      );
      await _persistSession(resp);
      return resp.user.toEntity();
    });
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    return _tryCatch(() async {
      final resp =
          await _remote.login(LoginRequest(email: email, password: password));
      await _persistSession(resp);
      return resp.user.toEntity();
    });
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await _local.getRefreshToken();
      if (refreshToken != null) {
        await _remote.logout(refreshToken);
      }
    } catch (_) {
      // Proceed with local cleanup even if remote call fails
    }
    await Future.wait([_local.clearTokens(), _local.clearUser()]);
    return const Right(null);
  }

  // ── Get cached user ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, User>> getCachedUser() async {
    try {
      final user = await _local.getCachedUser();
      if (user == null) return const Left(CacheFailure('No cached user found'));
      return Right(user.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ── Refresh token ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> refreshToken() async {
    return _tryCatch(() async {
      final storedRefresh = await _local.getRefreshToken();
      if (storedRefresh == null) throw Exception('No refresh token stored');
      final resp = await _remote.refreshToken(storedRefresh);
      await _local.saveTokens(
        accessToken: resp.accessToken,
        refreshToken: resp.refreshToken,
      );
      return resp.accessToken;
    });
  }

  // ── Biometric auth (Face ID / Fingerprint — device native) ────────────────
  //
  // Flow:
  //   1. Check device capability.
  //   2. Show native OS biometric prompt.
  //   3. On success, read the cached JWT and return the stored user.
  //      (No network call — biometric only unlocks the locally stored session.)

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<Failure, User>> authenticateWithBiometrics() async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        return const Left(
            BiometricFailure('Biometrics not available on this device'));
      }

// MOST COMPATIBLE (works with all versions)
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your biometric to log in to Delicious',
        biometricOnly: true,
      );

      if (!authenticated) {
        return const Left(
            BiometricFailure('Biometric authentication cancelled'));
      }

      // Retrieve the cached user — biometrics only unlocks the local session
      final user = await _local.getCachedUser();
      if (user == null) {
        return const Left(BiometricFailure(
            'No session found. Please log in with email first.'));
      }
      return Right(user.toEntity());
    } on PlatformException catch (e) {
      return Left(BiometricFailure(_mapBiometricError(e.code)));
    } catch (e) {
      return Left(BiometricFailure(e.toString()));
    }
  }

  String _mapBiometricError(String code) {
    switch (code) {
      case 'NotAvailable':
        return 'Biometrics not available on this device';
      case 'NotEnrolled':
        return 'No biometrics enrolled. Please set up Face ID or Fingerprint in device settings.';
      case 'LockedOut':
        return 'Biometrics locked. Try again later or use email login.';
      case 'PermanentlyLockedOut':
        return 'Biometrics permanently locked. Please use email login.';
      default:
        return 'Biometric authentication failed: $code';
    }
  }

  // ── Face vector auth (ML Kit — custom comparison) ─────────────────────────
  //
  // Flow for SETUP (one-time, in profile settings):
  //   1. Capture face image with camera.
  //   2. Extract 128-dim landmark vector with ML Kit.
  //   3. Call saveFaceVector() → POST /auth/face/save.
  //
  // Flow for LOGIN:
  //   1. Capture face image with camera.
  //   2. Extract vector.
  //   3. Call authenticateWithFaceVector() → POST /auth/face/login.
  //   4. Backend runs cosine similarity; returns JWT if >= 0.92.

  @override
  Future<Either<Failure, void>> saveFaceVector(List<double> vector) async {
    return _tryCatch(() async {
      await _remote.saveFaceVector(SaveFaceVectorRequest(vector));
      // Update cached user to reflect hasFaceAuth = true
      final cached = await _local.getCachedUser();
      if (cached != null) {
        await _local.saveUser(
          UserModel(
            id: cached.id,
            email: cached.email,
            name: cached.name,
            phone: cached.phone,
            avatarUrl: cached.avatarUrl,
            isGuest: cached.isGuest,
            hasFaceAuth: true,
            role: cached.role,
          ),
        );
      }
    });
  }

  @override
  Future<Either<Failure, User>> authenticateWithFaceVector(
      List<double> inputVector) async {
    if (inputVector.length != 128) {
      return const Left(
          FaceAuthFailure('Invalid face vector: must be 128 dimensions'));
    }
    return _tryCatch(() async {
      final resp =
          await _remote.authenticateWithFace(FaceAuthRequest(inputVector));
      await _persistSession(resp);
      return resp.user.toEntity();
    });
  }

  // ── Guest ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, User>> continueAsGuest() async {
    try {
      final guest = UserModel.guest();
      await _local.saveUser(guest);
      return Right(guest.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
