import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service AI On-Device cho phân loại triệu chứng sơ cứu
///
/// Member 2: Đây là lớp trung gian giữa TFLite model và BLoC.
/// Hiện tại sử dụng placeholder — khi model .tflite sẵn sàng,
/// chỉ cần implement phần [_runModelInference] bên dưới.
///
/// Flow: Symptom Text → Tokenizer → Model → Labels → FirstAidGuide
@lazySingleton
class FirstAidAiService {
  static const String _tag = 'FirstAidAiService';
  final Logger _logger = Logger();

  // ─── Trạng thái model ──────────────────────────────────────
  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  // ═══════════════════════════════════════════════════════════
  // TODO (Member 2): Khai báo biến TFLite interpreter ở đây
  // ═══════════════════════════════════════════════════════════
  //
  // import 'package:tflite_flutter/tflite_flutter.dart';
  //
  // Interpreter? _interpreter;
  // List<String> _labels = [];
  //
  // Đường dẫn model và labels:
  // static const String _modelPath = 'assets/models/first_aid_model.tflite';
  // static const String _labelsPath = 'assets/models/labels.txt';
  // static const String _vocabPath = 'assets/models/vocab.txt';
  //
  // ═══════════════════════════════════════════════════════════

  /// Khởi tạo và nạp model TFLite vào bộ nhớ
  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      _logger.i('[$_tag] Đang nạp mô hình AI On-Device...');

      // ═══════════════════════════════════════════════════════
      // TODO (Member 2): Nạp model TFLite
      // ═══════════════════════════════════════════════════════
      //
      // _interpreter = await Interpreter.fromAsset(_modelPath);
      //
      // final labelsData = await rootBundle.loadString(_labelsPath);
      // _labels = const LineSplitter().convert(labelsData);
      //
      // _logger.i('[$_tag] Model đã nạp: ${_interpreter!.getInputTensors()}');
      //
      // ═══════════════════════════════════════════════════════

      _isModelLoaded = true;
      _logger.i('[$_tag] ✅ Model sẵn sàng (placeholder mode)');
    } catch (e) {
      _logger.e('[$_tag] ❌ Lỗi nạp model: $e');
      _isModelLoaded = false;
    }
  }

  /// Giải phóng tài nguyên model khỏi bộ nhớ
  void dispose() {
    // ═══════════════════════════════════════════════════════
    // TODO (Member 2): Đóng interpreter
    // ═══════════════════════════════════════════════════════
    //
    // _interpreter?.close();
    //
    // ═══════════════════════════════════════════════════════
    _isModelLoaded = false;
    _logger.i('[$_tag] Model đã giải phóng');
  }

  /// Phân loại triệu chứng → trả về danh sách condition kèm confidence
  ///
  /// Input: "rắn cắn sưng đỏ đau nhói"
  /// Output: [AiPrediction(conditionId: "snake-bite-001", confidence: 0.92), ...]
  Future<List<AiPrediction>> predict(String symptomText) async {
    if (symptomText.trim().isEmpty) return [];

    _logger.i('[$_tag] Đang phân tích: "$symptomText"');

    // ═══════════════════════════════════════════════════════
    // TODO (Member 2): Thay thế bằng TFLite inference thật
    // ═══════════════════════════════════════════════════════
    //
    // if (!_isModelLoaded || _interpreter == null) {
    //   await loadModel();
    // }
    //
    // // 1. Tokenize input
    // final tokenizer = sl<TfliteTokenizer>();
    // final inputIds = tokenizer.tokenize(symptomText);
    //
    // // 2. Chuẩn bị tensor đầu vào
    // final input = [inputIds]; // shape: [1, maxSeqLength]
    //
    // // 3. Chuẩn bị tensor đầu ra
    // final output = List.filled(_labels.length, 0.0)
    //     .reshape([1, _labels.length]);
    //
    // // 4. Chạy suy luận
    // _interpreter!.run(input, output);
    //
    // // 5. Chuyển đổi output thành predictions
    // final scores = output[0] as List<double>;
    // final predictions = <AiPrediction>[];
    // for (int i = 0; i < scores.length; i++) {
    //   if (scores[i] > 0.1) { // Ngưỡng tin cậy tối thiểu
    //     predictions.add(AiPrediction(
    //       conditionId: _labels[i],
    //       conditionName: _labels[i],
    //       confidence: scores[i],
    //     ));
    //   }
    // }
    //
    // predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    // return predictions.take(5).toList();
    //
    // ═══════════════════════════════════════════════════════

    // ─── Placeholder: trả về kết quả mặc định dựa trên keyword ───
    return _fallbackKeywordMatching(symptomText);
  }

  /// Đo thời gian suy luận (cho benchmark)
  Future<AiBenchmarkResult> benchmark(String symptomText, {int runs = 10}) async {
    final stopwatch = Stopwatch();
    final latencies = <int>[];

    for (int i = 0; i < runs; i++) {
      stopwatch
        ..reset()
        ..start();
      await predict(symptomText);
      stopwatch.stop();
      latencies.add(stopwatch.elapsedMilliseconds);
    }

    latencies.sort();
    return AiBenchmarkResult(
      runs: runs,
      avgLatencyMs: latencies.reduce((a, b) => a + b) / runs,
      minLatencyMs: latencies.first.toDouble(),
      maxLatencyMs: latencies.last.toDouble(),
      p50LatencyMs: latencies[runs ~/ 2].toDouble(),
      p95LatencyMs: latencies[(runs * 0.95).floor()].toDouble(),
      isModelLoaded: _isModelLoaded,
    );
  }

  // ─── Fallback: keyword matching khi chưa có model ─────────
  List<AiPrediction> _fallbackKeywordMatching(String text) {
    final lower = text.toLowerCase();
    final results = <AiPrediction>[];

    final keywordMap = {
      'snake-bite-001': {
        'name': 'Rắn cắn',
        'keywords': ['rắn', 'cắn', 'snake', 'bite', 'nọc', 'venom'],
      },
      'hypothermia-001': {
        'name': 'Hạ thân nhiệt',
        'keywords': ['lạnh', 'run', 'rẩy', 'hypothermia', 'cold', 'tê', 'đông'],
      },
      'heat-exhaustion-001': {
        'name': 'Say nắng / Kiệt sức do nóng',
        'keywords': ['nóng', 'say', 'nắng', 'heat', 'khát', 'chóng mặt', 'kiệt'],
      },
      'fracture-001': {
        'name': 'Gãy xương / Bong gân',
        'keywords': ['gãy', 'xương', 'bong', 'gân', 'trật', 'khớp', 'fracture', 'sprain'],
      },
      'insect-sting-001': {
        'name': 'Ong đốt / Côn trùng cắn',
        'keywords': ['ong', 'đốt', 'côn trùng', 'sưng', 'ngứa', 'sting', 'insect'],
      },
      'bleeding-001': {
        'name': 'Chảy máu / Vết thương hở',
        'keywords': ['máu', 'chảy', 'vết thương', 'bleeding', 'cắt', 'rách'],
      },
      'altitude-sickness-001': {
        'name': 'Say độ cao',
        'keywords': ['độ cao', 'altitude', 'khó thở', 'nhức đầu', 'say'],
      },
      'dehydration-001': {
        'name': 'Mất nước',
        'keywords': ['khát', 'mất nước', 'dehydration', 'khô', 'tiểu ít'],
      },
      'burn-001': {
        'name': 'Bỏng',
        'keywords': ['bỏng', 'nóng', 'cháy', 'burn', 'phồng rộp'],
      },
      'drowning-001': {
        'name': 'Đuối nước',
        'keywords': ['đuối', 'nước', 'ngạt', 'drowning', 'hô hấp'],
      },
      'food-poisoning-001': {
        'name': 'Ngộ độc thực phẩm',
        'keywords': ['ngộ độc', 'nôn', 'tiêu chảy', 'bụng', 'food poison'],
      },
      'allergy-001': {
        'name': 'Phản ứng dị ứng',
        'keywords': ['dị ứng', 'allergy', 'nổi mẩn', 'sưng', 'phù'],
      },
    };

    for (final entry in keywordMap.entries) {
      final info = entry.value;
      final keywords = info['keywords'] as List<String>;
      int matchCount = 0;
      for (final kw in keywords) {
        if (lower.contains(kw)) matchCount++;
      }
      if (matchCount > 0) {
        final confidence = (matchCount / keywords.length).clamp(0.1, 0.95);
        results.add(AiPrediction(
          conditionId: entry.key,
          conditionName: info['name'] as String,
          confidence: confidence,
        ));
      }
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(5).toList();
  }
}

// ─── Data classes ──────────────────────────────────────────────

/// Kết quả dự đoán từ mô hình AI
class AiPrediction {
  final String conditionId;
  final String conditionName;
  final double confidence;

  const AiPrediction({
    required this.conditionId,
    required this.conditionName,
    required this.confidence,
  });

  @override
  String toString() =>
      'AiPrediction($conditionName, ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Kết quả benchmark hiệu năng AI
class AiBenchmarkResult {
  final int runs;
  final double avgLatencyMs;
  final double minLatencyMs;
  final double maxLatencyMs;
  final double p50LatencyMs;
  final double p95LatencyMs;
  final bool isModelLoaded;

  const AiBenchmarkResult({
    required this.runs,
    required this.avgLatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.p50LatencyMs,
    required this.p95LatencyMs,
    required this.isModelLoaded,
  });

  @override
  String toString() => '''
AI Benchmark ($runs runs):
  Avg: ${avgLatencyMs.toStringAsFixed(1)}ms
  P50: ${p50LatencyMs.toStringAsFixed(1)}ms  
  P95: ${p95LatencyMs.toStringAsFixed(1)}ms
  Min: ${minLatencyMs.toStringAsFixed(1)}ms
  Max: ${maxLatencyMs.toStringAsFixed(1)}ms
  Model loaded: $isModelLoaded''';
}

