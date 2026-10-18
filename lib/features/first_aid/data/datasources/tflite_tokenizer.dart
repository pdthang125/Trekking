import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Bộ tách từ & mã hoá văn bản (Tokenizer) trên thiết bị di động (Dart thuần)
/// Tương thích với mô hình phân loại intent triệu chứng NLP của Member 2
@lazySingleton
class TfliteTokenizer {
  static const int defaultMaxLength = 64;
  static const String padToken = '[PAD]';
  static const String unkToken = '[UNK]';
  static const String clsToken = '[CLS]';
  static const String sepToken = '[SEP]';

  final Map<String, int> _vocab = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Nạp từ điển từ file assets/models/vocab.txt
  Future<void> loadVocabulary({String vocabPath = 'assets/models/vocab.txt'}) async {
    try {
      final content = await rootBundle.loadString(vocabPath);
      final lines = const LineSplitter().convert(content);
      
      _vocab.clear();
      for (int i = 0; i < lines.length; i++) {
        final token = lines[i].trim();
        if (token.isNotEmpty) {
          _vocab[token] = i;
        }
      }
      _isInitialized = true;
    } catch (e) {
      // Fallback: khởi tạo từ điển từ khoá cơ bản nếu chưa có file vocab.txt
      _initFallbackVocabulary();
    }
  }

  void _initFallbackVocabulary() {
    final basicTokens = [
      padToken, unkToken, clsToken, sepToken,
      'người', 'lạnh', 'run', 'rẩy', 'sốt', 'nóng', 'say', 'nắng', 'rắn', 'cắn',
      'đau', 'sưng', 'chân', 'tay', 'khớp', 'ngã', 'ong', 'đốt', 'dị', 'ứng',
      'thở', 'khó', 'máu', 'chảy', 'ngộ', 'độc', 'nôn', 'bụng', 'đầu', 'chóng', 'mặt',
      'snake', 'bite', 'cold', 'fever', 'heat', 'pain', 'bleed', 'bone', 'sting'
    ];
    _vocab.clear();
    for (int i = 0; i < basicTokens.length; i++) {
      _vocab[basicTokens[i]] = i;
    }
    _isInitialized = true;
  }

  /// Tiền xử lý & chuyển đổi câu triệu chứng thành mảng Integer Tensor
  /// Input: "tôi bị rắn cắn ở chân"
  /// Output: [2, 8, 9, 12, 0, 0, ..., 0] (shape: [1, maxSeqLength])
  List<int> tokenize(String text, {int maxLength = defaultMaxLength}) {
    if (!_isInitialized) {
      _initFallbackVocabulary();
    }

    final normalized = _cleanText(text);
    final words = normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final List<int> tokens = [];
    
    // Thêm token bắt đầu [CLS] nếu có
    if (_vocab.containsKey(clsToken)) {
      tokens.add(_vocab[clsToken]!);
    }

    // Mã hoá từng từ thành ID
    for (final word in words) {
      if (tokens.length >= maxLength - 1) break;
      final tokenId = _vocab[word] ?? _vocab[unkToken] ?? 1;
      tokens.add(tokenId);
    }

    // Thêm token kết thúc [SEP] nếu còn chỗ
    if (tokens.length < maxLength && _vocab.containsKey(sepToken)) {
      tokens.add(_vocab[sepToken]!);
    }

    // Padding số 0 ([PAD]) cho đủ chiều dài maxLength
    final padId = _vocab[padToken] ?? 0;
    while (tokens.length < maxLength) {
      tokens.add(padId);
    }

    return tokens;
  }

  /// Chuẩn hoá chuỗi: chuyển chữ thường, loại bỏ ký tự đặc biệt
  String _cleanText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
