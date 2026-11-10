import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/ai_local_datasource.dart';
import '../datasources/ai_remote_datasource.dart';

@Injectable(as: AiAssistantRepository)
class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final NetworkInfo _networkInfo;
  final AiRemoteDatasource _remoteDatasource;
  final AiLocalDatasource _localDatasource;
  final Logger _logger = Logger();
  final _uuid = const Uuid();

  final List<ChatMessageEntity> _history = [];

  AiAssistantRepositoryImpl({
    required NetworkInfo networkInfo,
    required AiRemoteDatasource remoteDatasource,
    required AiLocalDatasource localDatasource,
  })  : _networkInfo = networkInfo,
        _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource;

  @override
  List<ChatMessageEntity> getConversationHistory() => List.unmodifiable(_history);

  @override
  void clearHistory() => _history.clear();

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String query,
    Duration cloudTimeout = const Duration(seconds: 5),
  }) async {
    final now = DateTime.now();

    // 1. Lưu tin nhắn người dùng vào lịch sử
    final userMessage = ChatMessageEntity(
      id: _uuid.v4(),
      text: query,
      isUser: true,
      source: MessageSource.user,
      timestamp: now,
    );
    _history.add(userMessage);

    // 2. Kiểm tra kết nối mạng
    final isOnline = await _networkInfo.isConnected;

    if (isOnline) {
      _logger.i('[AiRepository] 🌐 Phát hiện có kết nối mạng. Thử gọi Gemini Cloud...');
      try {
        // [Nhánh: Mạng Nhanh/Ổn định]
        final cloudText = await _remoteDatasource.askGemini(
          prompt: query,
          timeout: cloudTimeout,
        );

        final aiMessage = ChatMessageEntity(
          id: _uuid.v4(),
          text: cloudText,
          isUser: false,
          source: MessageSource.geminiCloud,
          timestamp: DateTime.now(),
        );

        _history.add(aiMessage);
        return Right(aiMessage);
      } catch (e) {
        // [Nhánh: Mạng Yếu / Timeout / Lỗi API Cloud] ➔ Fallback về Local Model
        _logger.w('[AiRepository] ⚠️ Gọi Cloud API thất bại hoặc quá hạn ($e). Chuyển hướng sang Local Model...');

        final localResult = await _localDatasource.processOfflineQuery(query);

        final fallbackMessage = ChatMessageEntity(
          id: _uuid.v4(),
          text: '📡 [Đã chuyển sang Local AI do mạng yếu/timeout]\n\n${localResult.textResponse}',
          isUser: false,
          source: MessageSource.localModel,
          timestamp: DateTime.now(),
          confidence: localResult.confidence,
          matchedConditionId: localResult.matchedGuideId,
        );

        _history.add(fallbackMessage);
        return Right(fallbackMessage);
      }
    } else {
      // [Nhánh: Mất kết nối Mạng] ➔ Đi thẳng vào Local Model
      _logger.i('[AiRepository] 📴 Không có mạng. Kích hoạt Local Model On-Device trực tiếp...');

      try {
        final localResult = await _localDatasource.processOfflineQuery(query);

        final localMessage = ChatMessageEntity(
          id: _uuid.v4(),
          text: localResult.textResponse,
          isUser: false,
          source: MessageSource.localModel,
          timestamp: DateTime.now(),
          confidence: localResult.confidence,
          matchedConditionId: localResult.matchedGuideId,
        );

        _history.add(localMessage);
        return Right(localMessage);
      } catch (e) {
        return Left(AIInferenceFailure(message: 'Lỗi chạy Local Model: $e'));
      }
    }
  }
}

