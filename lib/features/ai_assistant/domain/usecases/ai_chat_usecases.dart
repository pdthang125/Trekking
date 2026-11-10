import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message_entity.dart';
import '../repositories/ai_assistant_repository.dart';

@injectable
class SendChatMessageUseCase extends UseCase<ChatMessageEntity, SendChatParams> {
  final AiAssistantRepository repository;

  SendChatMessageUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessageEntity>> call(SendChatParams params) {
    return repository.sendMessage(
      query: params.query,
      cloudTimeout: params.cloudTimeout ?? const Duration(seconds: 5),
    );
  }
}

class SendChatParams extends Equatable {
  final String query;
  final Duration? cloudTimeout;

  const SendChatParams({required this.query, this.cloudTimeout});

  @override
  List<Object?> get props => [query, cloudTimeout];
}

@injectable
class GetChatHistoryUseCase {
  final AiAssistantRepository repository;
  GetChatHistoryUseCase(this.repository);

  List<ChatMessageEntity> call() => repository.getConversationHistory();
}

@injectable
class ClearChatHistoryUseCase {
  final AiAssistantRepository repository;
  ClearChatHistoryUseCase(this.repository);

  void call() => repository.clearHistory();
}

