// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase           _login;
  final RegisterUseCase        _register;
  final LogoutUseCase          _logout;
  final GetCachedUserUseCase   _getCachedUser;
  final BiometricAuthUseCase   _biometricAuth;
  final FaceAuthUseCase        _faceAuth;
  final SaveFaceVectorUseCase  _saveFaceVector;
  final GuestLoginUseCase      _guestLogin;

  AuthBloc({
    required LoginUseCase          loginUseCase,
    required RegisterUseCase       registerUseCase,
    required LogoutUseCase         logoutUseCase,
    required GetCachedUserUseCase  getCachedUserUseCase,
    required BiometricAuthUseCase  biometricAuthUseCase,
    required FaceAuthUseCase       faceAuthUseCase,
    required SaveFaceVectorUseCase saveFaceVectorUseCase,
    required GuestLoginUseCase     guestLoginUseCase,
  })  : _login          = loginUseCase,
        _register       = registerUseCase,
        _logout         = logoutUseCase,
        _getCachedUser  = getCachedUserUseCase,
        _biometricAuth  = biometricAuthUseCase,
        _faceAuth       = faceAuthUseCase,
        _saveFaceVector = saveFaceVectorUseCase,
        _guestLogin     = guestLoginUseCase,
        super(const AuthInitial()) {

    on<AuthCheckRequested>        (_onCheckRequested);
    on<AuthLoginRequested>        (_onLoginRequested);
    on<AuthRegisterRequested>     (_onRegisterRequested);
    on<AuthBiometricRequested>    (_onBiometricRequested);
    on<AuthBiometricCheckRequested>(_onBiometricCheckRequested);
    on<AuthFaceLoginRequested>    (_onFaceLoginRequested);
    on<AuthFaceVectorSaveRequested>(_onFaceVectorSaveRequested);
    on<AuthGuestRequested>        (_onGuestRequested);
    on<AuthLogoutRequested>       (_onLogoutRequested);
  }

  // ── AuthCheckRequested ─────────────────────────────────────────────────────
  // Called once in main() or the root widget to restore a previous session.

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final biometricAvailable = await _biometricAuth.isAvailable();

    final result = await _getCachedUser();
    result.fold(
      (failure) => emit(AuthUnauthenticated(biometricAvailable: biometricAvailable)),
      (user) {
        if (user.isGuest) {
          emit(AuthGuest(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      },
    );
  }

  // ── AuthLoginRequested ─────────────────────────────────────────────────────

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        type:    _mapFailureToErrorType(failure),
      )),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ── AuthRegisterRequested ──────────────────────────────────────────────────

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _register(
      RegisterParams(
        email:    event.email,
        password: event.password,
        name:     event.name,
        phone:    event.phone,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        type:    _mapFailureToErrorType(failure),
      )),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ── AuthBiometricCheckRequested ────────────────────────────────────────────
  // Only checks capability — does NOT authenticate. Used to show/hide the
  // biometric button on the login screen.

  Future<void> _onBiometricCheckRequested(
    AuthBiometricCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final available = await _biometricAuth.isAvailable();
    emit(AuthUnauthenticated(biometricAvailable: available));
  }

  // ── AuthBiometricRequested ─────────────────────────────────────────────────
  // Triggers the device's native biometric prompt.

  Future<void> _onBiometricRequested(
    AuthBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _biometricAuth();

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        type:    AuthErrorType.biometricFailed,
      )),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ── AuthFaceLoginRequested ─────────────────────────────────────────────────
  // The face capture widget provides the 128-dim vector extracted by ML Kit.

  Future<void> _onFaceLoginRequested(
    AuthFaceLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _faceAuth(FaceVectorParams(event.faceVector));

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        type:    AuthErrorType.faceAuthFailed,
      )),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ── AuthFaceVectorSaveRequested ────────────────────────────────────────────
  // Called from the profile settings page when the user sets up face login.

  Future<void> _onFaceVectorSaveRequested(
    AuthFaceVectorSaveRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _saveFaceVector(FaceVectorParams(event.faceVector));

    result.fold(
      (failure) => emit(AuthError(
        message: failure.message,
        type:    AuthErrorType.faceAuthFailed,
      )),
      (_) => emit(const AuthFaceVectorSaved()),
    );
  }

  // ── AuthGuestRequested ─────────────────────────────────────────────────────

  Future<void> _onGuestRequested(
    AuthGuestRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _guestLogin();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user)    => emit(AuthGuest(user)),
    );
  }

  // ── AuthLogoutRequested ────────────────────────────────────────────────────

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _logout();
    emit(const AuthUnauthenticated());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AuthErrorType _mapFailureToErrorType(Failure failure) {
    if (failure is UnauthorizedFailure) return AuthErrorType.invalidCredentials;
    if (failure is NetworkFailure)      return AuthErrorType.network;
    if (failure is FaceAuthFailure)     return AuthErrorType.faceAuthFailed;
    if (failure is BiometricFailure)    return AuthErrorType.biometricFailed;
    if (failure is ValidationFailure)   return AuthErrorType.validationError;
    return AuthErrorType.generic;
  }
}