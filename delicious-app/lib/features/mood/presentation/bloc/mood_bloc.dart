// lib/features/mood/presentation/bloc/mood_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/mood.dart';

part 'mood_event.dart';
part 'mood_state.dart';

class MoodBloc extends Bloc<MoodEvent, MoodState> {
  MoodBloc() : super(const MoodState()) {
    on<MoodCatalogueRequested>(_onCatalogueRequested);
    on<MoodSelected>          (_onSelected);
    on<MoodCleared>           (_onCleared);
    on<MoodSelectorOpened>    (_onSelectorOpened);
    on<MoodSelectorClosed>    (_onSelectorClosed);
  }

  Future<void> _onCatalogueRequested(
    MoodCatalogueRequested event,
    Emitter<MoodState> emit,
  ) async {
    if (state.moods.isNotEmpty) return;
    emit(state.copyWith(isLoading: true));
    await Future.microtask(() {});
    final sorted = [...MoodCatalogue.all.where((m) => m.isActive)]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    emit(state.copyWith(isLoading: false, moods: sorted));
  }

  Future<void> _onSelected(
    MoodSelected event,
    Emitter<MoodState> emit,
  ) async {
    HapticFeedback.mediumImpact();
    // Tapping the active mood deselects it
    if (event.moodTag == state.activeMoodTag) {
      emit(state.copyWith(clearMood: true, isSelectorOpen: false));
    } else {
      emit(state.copyWith(
        activeMoodTag:  event.moodTag,
        isSelectorOpen: false,
      ));
    }
  }

  Future<void> _onCleared(
    MoodCleared event,
    Emitter<MoodState> emit,
  ) async {
    HapticFeedback.lightImpact();
    emit(state.copyWith(clearMood: true));
  }

  Future<void> _onSelectorOpened(
    MoodSelectorOpened event,
    Emitter<MoodState> emit,
  ) async {
    if (state.moods.isEmpty) add(const MoodCatalogueRequested());
    emit(state.copyWith(isSelectorOpen: true));
  }

  Future<void> _onSelectorClosed(
    MoodSelectorClosed event,
    Emitter<MoodState> emit,
  ) async {
    emit(state.copyWith(isSelectorOpen: false));
  }
}