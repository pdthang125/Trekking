import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../../first_aid/data/datasources/first_aid_local_datasource.dart';
import '../../../first_aid/domain/entities/first_aid_entities.dart';

abstract class AiLocalDatasource {
  /// Dự đoán và trả về câu trả lời sơ cứu / sinh tồn ngoại tuyến
  Future<LocalAiResult> processOfflineQuery(String query);
}

class LocalAiResult {
  final String textResponse;
  final double confidence;
  final String? matchedGuideId;

  const LocalAiResult({
    required this.textResponse,
    required this.confidence,
    this.matchedGuideId,
  });
}

@Injectable(as: AiLocalDatasource)
class AiLocalDatasourceImpl implements AiLocalDatasource {
  final FirstAidLocalDatasource _firstAidLocal;
  final Logger _logger = Logger();

  AiLocalDatasourceImpl(this._firstAidLocal);

  @override
  Future<LocalAiResult> processOfflineQuery(String query) async {
    _logger.i('[AiLocalDatasource] ⚡ Đang xử lý qua Local Model ngoại tuyến: "$query"');

    // ═════════════════════════════════════════════════════════════════════
    // 🎯 CHỖ DÀNH CHO BẠN (MEMBER 2): NHÚNG MODEL RIÊNG ĐÃ TRAIN VÀO ĐÂY
    // ═════════════════════════════════════════════════════════════════════
    // Khi bạn huấn luyện xong model riêng (TFLite hoặc ONNX):
    // 1. Nạp interpreter:
    //    final interpreter = await Interpreter.fromAsset('assets/models/your_model.tflite');
    // 2. Tiền xử lý token:
    //    final inputTensor = tokenizer.tokenize(query);
    // 3. Chạy suy luận:
    //    interpreter.run(inputTensor, outputTensor);
    // 4. Lấy kết quả nhãn dự đoán và trả về LocalAiResult
    // ═════════════════════════════════════════════════════════════════════

    // ── FALLBACK NỘI BỘ THÔNG MINH (Hoạt động ngay lập tức trước khi có model) ──
    // Tra cứu cẩm nang sơ cứu offline từ cơ sở dữ liệu SQLite
    final matchedGuides = await _firstAidLocal.searchBySymptoms(query);

    if (matchedGuides.isNotEmpty) {
      final bestMatch = matchedGuides.first;
      final buffer = StringBuffer();
      buffer.writeln('📋 [Chẩn đoán Ngoại tuyến]: ${bestMatch.conditionNameVi}');
      buffer.writeln('⚠️ Mức độ: ${_severityText(bestMatch.severity)}');
      buffer.writeln('📌 Mô tả: ${bestMatch.descriptionVi}\n');
      buffer.writeln('👉 Các bước sơ cứu cần thực hiện ngay:');

      for (final step in bestMatch.steps) {
        buffer.writeln('${step.stepNumber}. ${step.instructionVi}');
      }

      if (bestMatch.doNotsVi.isNotEmpty) {
        buffer.writeln('\n⛔ TUYỆT ĐỐI KHÔNG:');
        for (final dont in bestMatch.doNotsVi) {
          buffer.writeln('• $dont');
        }
      }

      if (bestMatch.whenToEvacuateVi != null) {
        buffer.writeln('\n🚨 Di tản khẩn cấp khi: ${bestMatch.whenToEvacuateVi}');
      }

      return LocalAiResult(
        textResponse: buffer.toString(),
        confidence: 0.88,
        matchedGuideId: bestMatch.id,
      );
    }

    // Nếu không khớp bệnh lý chính xác, đưa ra chỉ dẫn sinh tồn cơ bản
    return LocalAiResult(
      textResponse: '🛡️ [Trợ lý Ngoại tuyến TrekGuard]\n\n'
          'Không tìm thấy bệnh lý trùng khớp hoàn toàn với triệu chứng "$query" trong cẩm nang dã ngoại.\n\n'
          '💡 Nguyên tắc sơ cứu dã ngoại căn bản (DRSABCD):\n'
          '1. Nguy hiểm (Danger): Đảm bảo an toàn cho bản thân và nạn nhân.\n'
          '2. Phản ứng (Response): Lay gọi, kiểm tra tri giác nạn nhân.\n'
          '3. Cứu hộ (Send for help): Nhấn giữ nút SOS 3 giây nếu nguy kịch.\n'
          '4. Đường thở (Airway): Giữ thông thoáng đường thở.\n'
          '5. Hơi thở (Breathing): Kiểm tra nạn nhân có thở không.\n'
          '6. Ép tim (CPR): Nếu không thở, bắt đầu CPR 30 lần ép - 2 lần thổi ngạt.',
      confidence: 0.5,
    );
  }

  String _severityText(SeverityLevel severity) => switch (severity) {
    SeverityLevel.danger => 'NGUY HIỂM — Cần xử lý khẩn cấp & di tản',
    SeverityLevel.warning => 'CẢNH BÁO — Cần theo dõi sát',
    SeverityLevel.safe => 'AN TOÀN — Có thể tự xử lý tại chỗ',
  };
}

