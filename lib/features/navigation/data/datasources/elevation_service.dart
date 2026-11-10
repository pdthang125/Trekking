import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/navigation_entities.dart';

/// Supabase PostGIS elevation service
/// 
/// Lấy dữ liệu độ cao cho các điểm GPS bằng cách:
/// 1. Kiểm tra cache elevation trong Supabase
/// 2. Nếu không có → trả về altitude từ GPS sensor (đã có sẵn)
/// 
/// Member 2: Khi triển khai Open-Elevation API hoặc OpenTopography,
/// implement phần [_fetchFromElevationApi] bên dưới.
@lazySingleton
class ElevationService {
  final SupabaseClient _client;
  final Logger _logger = Logger();
  static const String _tag = 'ElevationService';

  ElevationService(this._client);

  /// Lấy độ cao cho một toạ độ GPS
  Future<double?> getElevation(double latitude, double longitude) async {
    try {
      // 1. Kiểm tra cache trước
      final cached = await _checkCache(latitude, longitude);
      if (cached != null) return cached;

      // 2. Gọi API lấy độ cao
      final elevation = await _fetchFromElevationApi(latitude, longitude);
      if (elevation != null) {
        await _saveToCache(latitude, longitude, elevation);
      }
      return elevation;
    } catch (e) {
      _logger.w('[$_tag] Không thể lấy độ cao: $e');
      return null;
    }
  }

  /// Lấy độ cao cho danh sách toạ độ (batch)
  Future<List<double?>> getElevationBatch(List<GpsPoint> points) async {
    final results = <double?>[];
    for (final point in points) {
      final elevation = await getElevation(point.latitude, point.longitude);
      results.add(elevation ?? point.altitude);
    }
    return results;
  }

  /// Tính Elevation Gain và Elevation Loss từ danh sách track points
  ElevationStats calculateElevationStats(List<GpsPoint> points) {
    if (points.length < 2) {
      return const ElevationStats(
        elevationGain: 0,
        elevationLoss: 0,
        maxAltitude: 0,
        minAltitude: 0,
        avgAltitude: 0,
      );
    }

    double gain = 0;
    double loss = 0;
    double maxAlt = double.negativeInfinity;
    double minAlt = double.infinity;
    double totalAlt = 0;
    int validCount = 0;

    for (int i = 0; i < points.length; i++) {
      final alt = points[i].altitude;
      if (alt == null) continue;

      totalAlt += alt;
      validCount++;
      if (alt > maxAlt) maxAlt = alt;
      if (alt < minAlt) minAlt = alt;

      if (i > 0 && points[i - 1].altitude != null) {
        final diff = alt - points[i - 1].altitude!;
        if (diff > 0) {
          gain += diff;
        } else {
          loss += diff.abs();
        }
      }
    }

    return ElevationStats(
      elevationGain: gain,
      elevationLoss: loss,
      maxAltitude: maxAlt == double.negativeInfinity ? 0 : maxAlt,
      minAltitude: minAlt == double.infinity ? 0 : minAlt,
      avgAltitude: validCount > 0 ? totalAlt / validCount : 0,
    );
  }

  // ─── Private helpers ──────────────────────────────────────

  Future<double?> _checkCache(double lat, double lng) async {
    try {
      final response = await _client
          .from('elevation_cache')
          .select('elevation')
          .eq('latitude', _roundCoord(lat))
          .eq('longitude', _roundCoord(lng))
          .maybeSingle();

      if (response != null) {
        return (response['elevation'] as num).toDouble();
      }
    } catch (e) {
      // Cache miss hoặc bảng chưa tồn tại — bỏ qua
    }
    return null;
  }

  Future<void> _saveToCache(double lat, double lng, double elevation) async {
    try {
      await _client.from('elevation_cache').upsert({
        'latitude': _roundCoord(lat),
        'longitude': _roundCoord(lng),
        'elevation': elevation,
        'source': 'open-elevation',
      });
    } catch (e) {
      _logger.w('[$_tag] Không thể cache elevation: $e');
    }
  }

  /// Làm tròn toạ độ để cache hiệu quả (precision ~11m)
  double _roundCoord(double coord) => (coord * 10000).roundToDouble() / 10000;

  /// Gọi API lấy dữ liệu độ cao
  ///
  /// Member 2: Implement phần này khi tích hợp Open-Elevation API
  Future<double?> _fetchFromElevationApi(double lat, double lng) async {
    // ═══════════════════════════════════════════════════════
    // TODO (Member 2): Gọi Open-Elevation API hoặc OpenTopography
    // ═══════════════════════════════════════════════════════
    //
    // Ví dụ sử dụng Dio:
    //
    // final dio = Dio();
    // final response = await dio.get(
    //   'https://api.open-elevation.com/api/v1/lookup',
    //   queryParameters: {'locations': '$lat,$lng'},
    // );
    // if (response.statusCode == 200) {
    //   final results = response.data['results'] as List;
    //   if (results.isNotEmpty) {
    //     return (results[0]['elevation'] as num).toDouble();
    //   }
    // }
    //
    // ═══════════════════════════════════════════════════════

    // Placeholder: trả về null, sẽ dùng altitude từ GPS sensor
    return null;
  }
}

/// Thống kê độ cao cho một chuyến đi
class ElevationStats {
  final double elevationGain;
  final double elevationLoss;
  final double maxAltitude;
  final double minAltitude;
  final double avgAltitude;

  const ElevationStats({
    required this.elevationGain,
    required this.elevationLoss,
    required this.maxAltitude,
    required this.minAltitude,
    required this.avgAltitude,
  });

  /// Tổng chênh lệch độ cao
  double get totalElevationChange => elevationGain + elevationLoss;

  /// Độ dốc trung bình (nếu biết khoảng cách)
  double avgGradient(double distanceKm) {
    if (distanceKm <= 0) return 0;
    return (elevationGain / (distanceKm * 1000)) * 100; // phần trăm
  }

  @override
  String toString() => '''
ElevationStats:
  Gain: ${elevationGain.toStringAsFixed(0)}m
  Loss: ${elevationLoss.toStringAsFixed(0)}m
  Max: ${maxAltitude.toStringAsFixed(0)}m
  Min: ${minAltitude.toStringAsFixed(0)}m
  Avg: ${avgAltitude.toStringAsFixed(0)}m''';
}

