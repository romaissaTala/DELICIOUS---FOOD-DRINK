// lib/features/auth/presentation/bloc/auth_state.dart
part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial state before the session check completes.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Any async operation is in progress — show a spinner.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is fully authenticated (email, biometric, or face login succeeded).
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object> get props => [user];
}

/// User chose guest mode — allow browsing and checkout without an account.
class AuthGuest extends AuthState {
  final User guestUser;
  const AuthGuest(this.guestUser);
  @override
  List<Object> get props => [guestUser];
}

/// No session found / logout completed — route to login screen.
class AuthUnauthenticated extends AuthState {
  /// Whether the device supports biometrics (controls biometric button visibility).
  final bool biometricAvailable;
  const AuthUnauthenticated({this.biometricAvailable = false});
  @override
  List<Object> get props => [biometricAvailable];
}

/// An operation failed — show the error message, stay on the current screen.
class AuthError extends AuthState {
  final String message;
  final AuthErrorType type;
  const AuthError({required this.message, this.type = AuthErrorType.generic});
  @override
  List<Object> get props => [message, type];
}

/// Face vector saved successfully — show confirmation in the settings UI.
class AuthFaceVectorSaved extends AuthState {
  const AuthFaceVectorSaved();
}

enum AuthErrorType {
  generic,
  invalidCredentials,
  network,
  faceAuthFailed,
  biometricFailed,
  validationError,
}