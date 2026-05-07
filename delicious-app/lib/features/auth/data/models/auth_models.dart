// lib/features/auth/data/models/auth_models.dart
//
// Data-layer models: JSON serialisation + mapping to/from domain entities.
// In a real project use `freezed` + `json_serializable` to generate the
// boilerplate. Shown manually here so every field is explicit.

import '../../domain/entities/user.dart';

// ── Request payloads ─────────────────────────────────────────────────────────

class LoginRequest {
  final String email;
  final String password;
  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String  email;
  final String  password;
  final String? name;
  final String? phone;
  const RegisterRequest({
    required this.email,
    required this.password,
    this.name,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'email':    email,
        'password': password,
        if (name  != null) 'name':  name,
        if (phone != null) 'phone': phone,
      };
}

class SaveFaceVectorRequest {
  final List<double> faceVector;
  const SaveFaceVectorRequest(this.faceVector);

  Map<String, dynamic> toJson() => {'faceVector': faceVector};
}

class FaceAuthRequest {
  final List<double> faceVector;
  const FaceAuthRequest(this.faceVector);

  Map<String, dynamic> toJson() => {'faceVector': faceVector};
}

// ── Response models ──────────────────────────────────────────────────────────

class AuthResponse {
  final String    accessToken;
  final String    refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken:  json['accessToken']  as String,
        refreshToken: json['refreshToken'] as String,
        user:         UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class RefreshTokenResponse {
  final String accessToken;
  const RefreshTokenResponse({required this.accessToken});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      RefreshTokenResponse(accessToken: json['accessToken'] as String);
}

// ── UserModel: data-layer representation of a user ───────────────────────────

class UserModel {
  final String  id;
  final String  email;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final bool    isGuest;
  final bool    hasFaceAuth;
  final String  role;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatarUrl,
    this.isGuest     = false,
    this.hasFaceAuth = false,
    this.role        = 'customer',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:          (json['_id'] ?? json['id']) as String,
        email:       json['email']       as String,
        name:        json['name']        as String?,
        phone:       json['phone']       as String?,
        avatarUrl:   json['avatarUrl']   as String?,
        isGuest:     (json['isGuest']    as bool?) ?? false,
        hasFaceAuth: (json['hasFaceAuth'] as bool?) ?? false,
        role:        (json['role']       as String?) ?? 'customer',
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'email':       email,
        if (name      != null) 'name':       name,
        if (phone     != null) 'phone':      phone,
        if (avatarUrl != null) 'avatarUrl':  avatarUrl,
        'isGuest':     isGuest,
        'hasFaceAuth': hasFaceAuth,
        'role':        role,
      };

  /// Map data model → pure domain entity.
  User toEntity() => User(
        id:          id,
        email:       email,
        name:        name,
        phone:       phone,
        avatarUrl:   avatarUrl,
        isGuest:     isGuest,
        hasFaceAuth: hasFaceAuth,
        role:        role,
      );

  /// Create a guest user model locally (no network call).
  factory UserModel.guest() => UserModel(
        id:      'guest_${DateTime.now().millisecondsSinceEpoch}',
        email:   'guest@delicious.dz',
        isGuest: true,
      );
}