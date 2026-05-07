// lib/features/mood/presentation/bloc/mood_state.dart
part of 'mood_bloc.dart';

class MoodState extends Equatable {
  final List<Mood> moods;
  final String?    activeMoodTag;
  final bool       isLoading;
  final bool       isSelectorOpen;
  final String?    errorMessage;

  const MoodState({
    this.moods          = const [],
    this.activeMoodTag,
    this.isLoading      = false,
    this.isSelectorOpen = false,
    this.errorMessage,
  });

  Mood? get activeMood =>
      activeMoodTag == null ? null : MoodCatalogue.byTag(activeMoodTag!);

  bool get hasActiveMood => activeMoodTag != null;

  /// Gradient colours for GradientScaffold when a mood is active.
  List<String> get activeGradientColors =>
      activeMood?.gradientColors ?? ['#FF6B35', '#FF8C61'];

  MoodState copyWith({
    List<Mood>? moods,
    String?     activeMoodTag,
    bool        clearMood      = false,
    bool?       isLoading,
    bool?       isSelectorOpen,
    String?     errorMessage,
    bool        clearError     = false,
  }) =>
      MoodState(
        moods:          moods          ?? this.moods,
        activeMoodTag:  clearMood      ? null : activeMoodTag ?? this.activeMoodTag,
        isLoading:      isLoading      ?? this.isLoading,
        isSelectorOpen: isSelectorOpen ?? this.isSelectorOpen,
        errorMessage:   clearError     ? null : errorMessage  ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [moods, activeMoodTag, isLoading, isSelectorOpen, errorMessage];
}