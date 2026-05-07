// lib/features/mood/presentation/bloc/mood_event.dart
part of 'mood_bloc.dart';

abstract class MoodEvent extends Equatable {
  const MoodEvent();
  @override
  List<Object?> get props => [];
}

/// Load the catalogue on first open.
class MoodCatalogueRequested extends MoodEvent {
  const MoodCatalogueRequested();
}

/// User taps a mood tile — selects or deselects.
class MoodSelected extends MoodEvent {
  final String moodTag;
  const MoodSelected(this.moodTag);
  @override
  List<Object> get props => [moodTag];
}

/// User taps the clear chip or the active mood again.
class MoodCleared extends MoodEvent {
  const MoodCleared();
}

/// Selector bottom sheet is opening.
class MoodSelectorOpened extends MoodEvent {
  const MoodSelectorOpened();
}

/// Selector bottom sheet is closing.
class MoodSelectorClosed extends MoodEvent {
  const MoodSelectorClosed();
}