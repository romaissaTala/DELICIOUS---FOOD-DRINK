// lib/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Check secure storage on app launch — restore session if token exists.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Standard email + password login.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

/// New account registration.
class AuthRegisterRequested extends AuthEvent {
  final String  email;
  final String  password;
  final String? name;
  final String? phone;
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.name,
    this.phone,
  });
  @override
  List<Object?> get props => [email, password, name, phone];
}

/// Trigger the device's native biometric prompt (Face ID / fingerprint).
class AuthBiometricRequested extends AuthEvent {
  const AuthBiometricRequested();
}

/// Check once at login screen load whether biometrics are available.
class AuthBiometricCheckRequested extends AuthEvent {
  const AuthBiometricCheckRequested();
}

/// Authenticate using the ML Kit face vector captured from the camera.
class AuthFaceLoginRequested extends AuthEvent {
  final List<double> faceVector;
  const AuthFaceLoginRequested(this.faceVector);
  @override
  List<Object> get props => [faceVector];
}

/// Save the user's face vector after they set up face login in settings.
class AuthFaceVectorSaveRequested extends AuthEvent {
  final List<double> faceVector;
  const AuthFaceVectorSaveRequested(this.faceVector);
  @override
  List<Object> get props => [faceVector];
}

/// Enter the app without creating an account.
class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

/// Sign out and clear all local session data.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}