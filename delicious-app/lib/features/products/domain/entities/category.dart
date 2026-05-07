// lib/features/products/domain/entities/category.dart
import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String       id;
  final String       name;
  final String       type;         // food | juice | coffee | sweets
  final String       icon;
  final int          sortOrder;
  final bool         isActive;
  final List<String> gradientColors;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.sortOrder     = 0,
    this.isActive      = true,
    this.gradientColors = const ['#FF6B35', '#FF8C61'],
  });

  @override
  List<Object> get props => [id, name, type];
}