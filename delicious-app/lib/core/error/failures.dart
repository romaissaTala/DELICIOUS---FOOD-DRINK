// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object> get props => [message];
}

class ServerFailure       extends Failure { const ServerFailure(super.message); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure(super.message); }
class NetworkFailure      extends Failure { const NetworkFailure(super.message); }
class CacheFailure        extends Failure { const CacheFailure(super.message); }
class FaceAuthFailure     extends Failure { const FaceAuthFailure(super.message); }
class BiometricFailure    extends Failure { const BiometricFailure(super.message); }
class ValidationFailure   extends Failure { const ValidationFailure(super.message); }