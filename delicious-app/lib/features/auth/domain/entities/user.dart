// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String  id;
  final String  email;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final bool    isGuest;
  final bool    hasFaceAuth;
  final String  role;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatarUrl,
    this.isGuest    = false,
    this.hasFaceAuth = false,
    this.role       = 'customer',
  });

  bool get isAdmin => role == 'admin';

  User copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    bool?   hasFaceAuth,
  }) =>
      User(
        id:          id,
        email:       email,
        name:        name        ?? this.name,
        phone:       phone       ?? this.phone,
        avatarUrl:   avatarUrl   ?? this.avatarUrl,
        isGuest:     isGuest,
        hasFaceAuth: hasFaceAuth ?? this.hasFaceAuth,
        role:        role,
      );

  @override
  List<Object?> get props => [id, email, name, phone, isGuest, hasFaceAuth, role];
}