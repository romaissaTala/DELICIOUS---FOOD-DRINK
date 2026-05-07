// lib/features/mood/domain/entities/mood.dart
import 'package:equatable/equatable.dart';

class Mood extends Equatable {
  final String       tag;
  final String       emoji;
  final String       label;
  final String       description;
  final List<String> gradientColors;
  final List<String> particleEmojis;
  final int          sortOrder;
  final bool         isActive;

  const Mood({
    required this.tag,
    required this.emoji,
    required this.label,
    required this.description,
    required this.gradientColors,
    this.particleEmojis = const [],
    this.sortOrder      = 0,
    this.isActive       = true,
  });

  @override
  List<Object> get props => [tag];
}

abstract class MoodCatalogue {
  static const List<Mood> all = [
    Mood(
      tag: 'cold', emoji: '🧊', label: 'Cold',
      description: 'Something icy & refreshing',
      gradientColors: ['#0EA5E9', '#38BDF8'],
      particleEmojis: ['❄️', '🧊', '💧', '🫧'],
      sortOrder: 1,
    ),
    Mood(
      tag: 'hot', emoji: '🔥', label: 'Hot',
      description: 'Warm up with something cozy',
      gradientColors: ['#EA580C', '#FB923C'],
      particleEmojis: ['🔥', '♨️', '☕', '🌶'],
      sortOrder: 2,
    ),
    Mood(
      tag: 'sweet', emoji: '🍬', label: 'Sweet',
      description: 'Sugar, spice & everything nice',
      gradientColors: ['#DB2777', '#F472B6'],
      particleEmojis: ['🍬', '🍭', '🍰', '🧁'],
      sortOrder: 3,
    ),
    Mood(
      tag: 'salty', emoji: '🧂', label: 'Salty',
      description: 'Savoury cravings handled',
      gradientColors: ['#64748B', '#94A3B8'],
      particleEmojis: ['🧂', '🥨', '🍟', '🥓'],
      sortOrder: 4,
    ),
    Mood(
      tag: 'spicy', emoji: '🌶', label: 'Spicy',
      description: 'Turn up the heat',
      gradientColors: ['#B91C1C', '#EF4444'],
      particleEmojis: ['🌶', '🫑', '🌶', '🔥'],
      sortOrder: 5,
    ),
    Mood(
      tag: 'fresh', emoji: '🌿', label: 'Fresh',
      description: 'Light, clean & natural',
      gradientColors: ['#16A34A', '#4ADE80'],
      particleEmojis: ['🌿', '🍃', '🥗', '🥒'],
      sortOrder: 6,
    ),
    Mood(
      tag: 'energising', emoji: '⚡', label: 'Energy',
      description: 'Fuel for the day ahead',
      gradientColors: ['#CA8A04', '#FACC15'],
      particleEmojis: ['⚡', '💪', '🏃', '🎯'],
      sortOrder: 7,
    ),
    Mood(
      tag: 'comforting', emoji: '🤗', label: 'Comfort',
      description: 'Wrap yourself in flavour',
      gradientColors: ['#92400E', '#D97706'],
      particleEmojis: ['🤗', '☕', '🍲', '🥐'],
      sortOrder: 8,
    ),
  ];

  static Mood? byTag(String tag) =>
      all.where((m) => m.tag == tag).firstOrNull;
}