import 'package:equatable/equatable.dart';
import '../../domain/entities/first_aid_entities.dart';

/// States for FirstAidBloc
abstract class FirstAidState extends Equatable {
  const FirstAidState();
  @override
  List<Object?> get props => [];
}

/// Initial state
class FirstAidInitial extends FirstAidState {
  const FirstAidInitial();
}

/// Loading (AI inference running)
class FirstAidLoading extends FirstAidState {
  const FirstAidLoading();
}

/// Successfully predicted/loaded guides
class FirstAidLoaded extends FirstAidState {
  final List<FirstAidGuide> guides;
  final String? query;
  final bool isFromAI;

  const FirstAidLoaded({
    required this.guides,
    this.query,
    this.isFromAI = false,
  });

  @override
  List<Object?> get props => [guides, query, isFromAI];
}

/// Specific guide detail loaded
class FirstAidDetailLoaded extends FirstAidState {
  final FirstAidGuide guide;
  const FirstAidDetailLoaded({required this.guide});

  @override
  List<Object?> get props => [guide];
}

/// Error state
class FirstAidError extends FirstAidState {
  final String message;
  const FirstAidError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Speaking TTS state
class FirstAidSpeaking extends FirstAidState {
  final FirstAidGuide guide;
  final int currentStep;
  const FirstAidSpeaking({required this.guide, required this.currentStep});

  @override
  List<Object?> get props => [guide, currentStep];
}

// ─────────────────────────────────────────────────────────────────────────────

/// Events for FirstAidBloc
abstract class FirstAidEvent extends Equatable {
  const FirstAidEvent();
  @override
  List<Object?> get props => [];
}

class LoadAllGuidesEvent extends FirstAidEvent {
  const LoadAllGuidesEvent();
}

class PredictFromSymptomsEvent extends FirstAidEvent {
  final String symptomText;
  final bool useOnDevice;
  const PredictFromSymptomsEvent({
    required this.symptomText,
    this.useOnDevice = true,
  });

  @override
  List<Object?> get props => [symptomText, useOnDevice];
}

class SearchGuidesEvent extends FirstAidEvent {
  final String query;
  const SearchGuidesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class LoadGuideDetailEvent extends FirstAidEvent {
  final String guideId;
  const LoadGuideDetailEvent({required this.guideId});

  @override
  List<Object?> get props => [guideId];
}

class SpeakGuideEvent extends FirstAidEvent {
  final FirstAidGuide guide;
  const SpeakGuideEvent({required this.guide});

  @override
  List<Object?> get props => [guide];
}

class StopSpeakingEvent extends FirstAidEvent {
  const StopSpeakingEvent();
}
