import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';

// ─── States ─────────────────────────────────────────────────────────────

abstract class AiAssistantState extends Equatable {
  final List<ChatMessageEntity> messages;
  final bool isOnline;

  const AiAssistantState({
    this.messages = const [],
    this.isOnline = true,
  });

  @override
  List<Object?> get props => [messages, isOnline];
}

class AiAssistantInitial extends AiAssistantState {
  const AiAssistantInitial({super.messages, super.isOnline});
}

class AiAssistantLoading extends AiAssistantState {
  const AiAssistantLoading({required super.messages, super.isOnline});
}

class AiAssistantLoaded extends AiAssistantState {
  final ChatMessageEntity lastMessage;

  const AiAssistantLoaded({
    required super.messages,
    required this.lastMessage,
    super.isOnline,
  });

  @override
  List<Object?> get props => [messages, lastMessage, isOnline];
}

class AiAssistantError extends AiAssistantState {
  final String errorMessage;

  const AiAssistantError({
    required super.messages,
    required this.errorMessage,
    super.isOnline,
  });

  @override
  List<Object?> get props => [messages, errorMessage, isOnline];
}

// ─── Events ─────────────────────────────────────────────────────────────

abstract class AiAssistantEvent extends Equatable {
  const AiAssistantEvent();
  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends AiAssistantEvent {
  final String query;
  const SendMessageEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ConnectivityChangedEvent extends AiAssistantEvent {
  final bool isOnline;
  const ConnectivityChangedEvent(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

class ClearHistoryEvent extends AiAssistantEvent {
  const ClearHistoryEvent();
}

