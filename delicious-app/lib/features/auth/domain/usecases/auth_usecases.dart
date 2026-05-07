// lib/features/auth/domain/usecases/auth_usecases.dart
//
// All auth use-cases in one file for brevity.
// Each is a tiny class with a single `call()` method — thin wrappers
// around the repository that keep Blocs free of repository details.

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

// ── Params ────────────────────────────────────────────────────────────────────

class LoginParams extends Equatable {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class RegisterParams extends Equatable {
  final String  email;
  final String  password;
  final String? name;
  final String? phone;
  const RegisterParams({
    required this.email,
    required this.password,
    this.name,
    this.phone,
  });
  @override
  List<Object?> get props => [email, password, name, phone];
}

class FaceVectorParams extends Equatable {
  final List<double> vector;
  const FaceVectorParams(this.vector);
  @override
  List<Object> get props => [vector];
}

// ── Use cases ─────────────────────────────────────────────────────────────────

class LoginUseCase {
  final AuthRepository _repo;
  const LoginUseCase(this._repo);

  Future<Either<Failure, User>> call(LoginParams p) =>
      _repo.login(email: p.email, password: p.password);
}

class RegisterUseCase {
  final AuthRepository _repo;
  const RegisterUseCase(this._repo);

  Future<Either<Failure, User>> call(RegisterParams p) =>
      _repo.register(
        email:    p.email,
        password: p.password,
        name:     p.name,
        phone:    p.phone,
      );
}

class LogoutUseCase {
  final AuthRepository _repo;
  const LogoutUseCase(this._repo);

  Future<Either<Failure, void>> call() => _repo.logout();
}

class GetCachedUserUseCase {
  final AuthRepository _repo;
  const GetCachedUserUseCase(this._repo);

  Future<Either<Failure, User>> call() => _repo.getCachedUser();
}

class BiometricAuthUseCase {
  final AuthRepository _repo;
  const BiometricAuthUseCase(this._repo);

  Future<Either<Failure, User>> call() => _repo.authenticateWithBiometrics();
  Future<bool> isAvailable()           => _repo.isBiometricAvailable();
}

class SaveFaceVectorUseCase {
  final AuthRepository _repo;
  const SaveFaceVectorUseCase(this._repo);

  Future<Either<Failure, void>> call(FaceVectorParams p) =>
      _repo.saveFaceVector(p.vector);
}

class FaceAuthUseCase {
  final AuthRepository _repo;
  const FaceAuthUseCase(this._repo);

  Future<Either<Failure, User>> call(FaceVectorParams p) =>
      _repo.authenticateWithFaceVector(p.vector);
}

class GuestLoginUseCase {
  final AuthRepository _repo;
  const GuestLoginUseCase(this._repo);

  Future<Either<Failure, User>> call() => _repo.continueAsGuest();
}