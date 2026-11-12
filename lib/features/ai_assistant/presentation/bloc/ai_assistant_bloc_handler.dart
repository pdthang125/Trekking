import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/usecases/ai_chat_usecases.dart';
import 'ai_assistant_bloc.dart';

export 'ai_assistant_bloc.dart';

@injectable
class AiAssistantBlocHandler extends Bloc<AiAssistantEvent, AiAssistantState> {
  final SendChatMessageUseCase _sendChatMessage;
  final GetChatHistoryUseCase _getChatHistory;
  final ClearChatHistoryUseCase _clearChatHistory;
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _networkSubscription;

  AiAssistantBlocHandler({
    required SendChatMessageUseCase sendChatMessage,
    required GetChatHistoryUseCase getChatHistory,
    required ClearChatHistoryUseCase clearChatHistory,
    required NetworkInfo networkInfo,
  })  : _sendChatMessage = sendChatMessage,
        _getChatHistory = getChatHistory,
        _clearChatHistory = clearChatHistory,
        _networkInfo = networkInfo,
        super(const AiAssistantInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<ConnectivityChangedEvent>(_onConnectivityChanged);
    on<ClearHistoryEvent>(_onClearHistory);

    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _networkSubscription = _networkInfo.connectivityStream.listen((isOnline) {
      add(ConnectivityChangedEvent(isOnline));
    });

    // Kiểm tra trạng thái ban đầu
    _networkInfo.isConnected.then((isOnline) {
      add(ConnectivityChangedEvent(isOnline));
    });
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AiAssistantState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    // Hiển thị ngay tin nhắn người dùng và trạng thái đang suy nghĩ
    final userPreview = ChatMessageEntity(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      isUser: true,
      source: MessageSource.user,
      timestamp: DateTime.now(),
    );
    final currentHistory = [..._getChatHistory(), userPreview];
    emit(AiAssistantLoading(
      messages: currentHistory,
      isOnline: state.isOnline,
    ));

    final result = await _sendChatMessage(SendChatParams(query: query));

    result.fold(
      (failure) => emit(AiAssistantError(
        messages: _getChatHistory(),
        errorMessage: failure.message,
        isOnline: state.isOnline,
      )),
      (response) => emit(AiAssistantLoaded(
        messages: _getChatHistory(),
        lastMessage: response,
        isOnline: state.isOnline,
      )),
    );
  }

  void _onConnectivityChanged(
    ConnectivityChangedEvent event,
    Emitter<AiAssistantState> emit,
  ) {
    emit(AiAssistantInitial(
      messages: state.messages,
      isOnline: event.isOnline,
    ));
  }

  void _onClearHistory(
    ClearHistoryEvent event,
    Emitter<AiAssistantState> emit,
  ) {
    _clearChatHistory();
    emit(AiAssistantInitial(
      messages: const [],
      isOnline: state.isOnline,
    ));
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    return super.close();
  }
}

