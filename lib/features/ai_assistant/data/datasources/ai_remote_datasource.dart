import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../../../core/env/env.dart';

abstract class AiRemoteDatasource {
  Future<String> askGemini({
    required String prompt,
    Duration timeout = const Duration(seconds: 5),
  });
}

@Injectable(as: AiRemoteDatasource)
class AiRemoteDatasourceImpl implements AiRemoteDatasource {
  final Logger _logger = Logger();
  GenerativeModel? _model;

  AiRemoteDatasourceImpl() {
    _initGemini();
  }

  void _initGemini() {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY') {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          'Bạn là TrekGuard AI — Chuyên gia y tế dã ngoại và sinh tồn nơi hoang dã. '
          'Hãy trả lời ngắn gọn, rõ ràng, ưu tiên các bước xử lý cấp cứu khẩn cấp theo chuẩn sơ cứu quốc tế. '
          'Nếu gặp trường hợp nguy kịch, luôn nhắc người dùng gọi 112/115 hoặc bật còi SOS.',
        ),
      );
    }
  }

  @override
  Future<String> askGemini({
    required String prompt,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_model == null) {
      throw const FormatException('GEMINI_API_KEY chưa được cấu hình hợp lệ');
    }

    _logger.i('[AiRemoteDatasource] ☁️ Đang gửi truy vấn lên Gemini (timeout: ${timeout.inSeconds}s)...');

    // Chạy với timeout kiểm soát để nhận biết mạng yếu
    final response = await _model!
        .generateContent([Content.text(prompt)])
        .timeout(
          timeout,
          onTimeout: () => throw TimeoutException('Mạng yếu hoặc Cloud API phản hồi quá hạn (${timeout.inSeconds}s)'),
        );

    final reply = response.text;
    if (reply == null || reply.trim().isEmpty) {
      throw Exception('Không nhận được nội dung từ Gemini Cloud');
    }

    return reply.trim();
  }
}

