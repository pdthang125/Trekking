import 'package:equatable/equatable.dart';

/// Nguồn xử lý câu trả lời
enum MessageSource {
  user,
  geminiCloud, // Xử lý trực tuyến qua Gemini API
  localModel,  // Xử lý ngoại tuyến bằng On-Device Model (Member 2 train riêng)
  system,      // Thông báo hệ thống / chuyển luồng
}

/// Thực thể tin nhắn trong chatbot
class ChatMessageEntity extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final MessageSource source;
  final DateTime timestamp;
  final double? confidence; // Độ tin cậy nếu đến từ local model
  final String? matchedConditionId; // ID bệnh lý sơ cứu nếu khớp

  const ChatMessageEntity({
    required this.id,
    required this.text,
    required this.isUser,
    required this.source,
    required this.timestamp,
    this.confidence,
    this.matchedConditionId,
  });

  @override
  List<Object?> get props => [id, text, isUser, source, timestamp];
}

