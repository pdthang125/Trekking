import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/usecases/first_aid_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import 'first_aid_states_events.dart';

export 'first_aid_states_events.dart';

@injectable
class FirstAidBlocHandler extends Bloc<FirstAidEvent, FirstAidState> {
  final PredictFirstAidUseCase predictUseCase;
  final GetAllFirstAidGuidesUseCase getAllGuidesUseCase;
  final SearchFirstAidGuidesUseCase searchGuidesUseCase;
  final GetFirstAidGuideByIdUseCase getGuideByIdUseCase;
  final SeedFirstAidDatabaseUseCase seedDatabaseUseCase;
  final FlutterTts _tts = FlutterTts();

  FirstAidBlocHandler({
    required this.predictUseCase,
    required this.getAllGuidesUseCase,
    required this.searchGuidesUseCase,
    required this.getGuideByIdUseCase,
    required this.seedDatabaseUseCase,
  }) : super(const FirstAidInitial()) {
    on<LoadAllGuidesEvent>(_onLoadAll);
    on<PredictFromSymptomsEvent>(_onPredict);
    on<SearchGuidesEvent>(_onSearch);
    on<LoadGuideDetailEvent>(_onLoadDetail);
    on<SpeakGuideEvent>(_onSpeak);
    on<StopSpeakingEvent>(_onStopSpeaking);

    _initTts();
  }

  void _initTts() {
    _tts.setLanguage('vi-VN');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  Future<void> _onLoadAll(
    LoadAllGuidesEvent event,
    Emitter<FirstAidState> emit,
  ) async {
    emit(const FirstAidLoading());
    final result = await getAllGuidesUseCase(NoParams());
    result.fold(
      (failure) => emit(FirstAidError(message: failure.message)),
      (guides) => emit(FirstAidLoaded(guides: guides)),
    );
  }

  Future<void> _onPredict(
    PredictFromSymptomsEvent event,
    Emitter<FirstAidState> emit,
  ) async {
    emit(const FirstAidLoading());
    final result = await predictUseCase(PredictParams(
      symptomText: event.symptomText,
      useOnDevice: event.useOnDevice,
    ));
    result.fold(
      (failure) => emit(FirstAidError(message: failure.message)),
      (guides) => emit(FirstAidLoaded(
        guides: guides,
        query: event.symptomText,
        isFromAI: true,
      )),
    );
  }

  Future<void> _onSearch(
    SearchGuidesEvent event,
    Emitter<FirstAidState> emit,
  ) async {
    emit(const FirstAidLoading());
    final result = await searchGuidesUseCase(event.query);
    result.fold(
      (failure) => emit(FirstAidError(message: failure.message)),
      (guides) => emit(FirstAidLoaded(guides: guides, query: event.query)),
    );
  }

  Future<void> _onLoadDetail(
    LoadGuideDetailEvent event,
    Emitter<FirstAidState> emit,
  ) async {
    emit(const FirstAidLoading());
    final result = await getGuideByIdUseCase(event.guideId);
    result.fold(
      (failure) => emit(FirstAidError(message: failure.message)),
      (guide) => emit(FirstAidDetailLoaded(guide: guide)),
    );
  }

  Future<void> _onSpeak(
    SpeakGuideEvent event,
    Emitter<FirstAidState> emit,
  ) async {
    final guide = event.guide;
    emit(FirstAidSpeaking(guide: guide, currentStep: 0));

    // Read each step sequentially
    for (int i = 0; i < guide.steps.length; i++) {
      if (state is! FirstAidSpeaking) break; // user stopped
      emit(FirstAidSpeaking(guide: guide, currentStep: i));
      final text = 'Bước ${i + 1}: ${guide.steps[i].instructionVi}';
      await _tts.speak(text);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _onStopSpeaking(
    StopSpeakingEvent event,
    Emitter<FirstAidState> emit,
  ) async {
    await _tts.stop();
    emit(const FirstAidInitial());
  }

  @override
  Future<void> close() {
    _tts.stop();
    return super.close();
  }
}
