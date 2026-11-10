import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_message_entity.dart';

abstract class AiAssistantRepository {
  /// Xử lý tin nhắn theo luồng: Cloud (Gemini) -> Timeout/Weak -> Local Model
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String query,
    Duration cloudTimeout = const Duration(seconds: 5),
  });

  /// Lấy lịch sử hội thoại hiện tại
  List<ChatMessageEntity> getConversationHistory();

  /// Xoá lịch sử hội thoại
  void clearHistory();
}

