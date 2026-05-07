// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Pure domain contract — no Dio, no Hive, no Flutter imports.
/// The data layer implements this; the domain layer only depends on it.
abstract class AuthRepository {
  // ── Standard auth ─────────────────────────────────────────────────────────

  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? name,
    String? phone,
  });

  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  /// Returns the cached user from secure storage without hitting the network.
  Future<Either<Failure, User>> getCachedUser();

  // ── Token management ──────────────────────────────────────────────────────

  Future<Either<Failure, String>> refreshToken();

  // ── Biometric auth (Face ID / Fingerprint via local_auth) ─────────────────

  /// Triggers the device's native biometric prompt.
  /// On success the stored JWT is returned and the user is considered logged in.
  Future<Either<Failure, User>> authenticateWithBiometrics();

  /// Returns true if the device supports biometrics and the user has enrolled.
  Future<bool> isBiometricAvailable();

  // ── Face vector auth (ML Kit — custom face comparison) ───────────────────

  /// Saves a 128-dim face vector to the backend and marks hasFaceAuth = true.
  Future<Either<Failure, void>> saveFaceVector(List<double> vector);

  /// Compares [inputVector] against the stored vector.
  /// Returns the authenticated User if similarity >= threshold (0.92).
  Future<Either<Failure, User>> authenticateWithFaceVector(
      List<double> inputVector);

  // ── Guest ─────────────────────────────────────────────────────────────────

  Future<Either<Failure, User>> continueAsGuest();
}