import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Màn hình Quản lý Bản đồ Ngoại tuyến (Offline Map Manager)
/// Cho phép tải trước gạch bản đồ OpenStreetMap về bộ nhớ điện thoại để đi rừng không cần mạng
class OfflineMapManagerPage extends StatefulWidget {
  const OfflineMapManagerPage({super.key});

  @override
  State<OfflineMapManagerPage> createState() => _OfflineMapManagerPageState();
}

class _OfflineMapManagerPageState extends State<OfflineMapManagerPage> {
  // Dung lượng mẫu
  final double _usedStorageMb = 113.0;
  final double _maxStorageMb = 500.0;

  // Danh sách các gói bản đồ dã ngoại trọng điểm
  final List<Map<String, dynamic>> _mapPacks = [
    {
      'id': 'son_tra',
      'title': 'Bán đảo Sơn Trà & Đỉnh Bàn Cờ',
      'location': 'Đà Nẵng',
      'sizeMb': 48,
      'isDownloaded': true,
      'zoomRange': 'Zoom 10–16',
      'trailsCount': 6,
    },
    {
      'id': 'ba_na',
      'title': 'Rừng nguyên sinh Bà Nà - Núi Chúa',
      'location': 'Đà Nẵng',
      'sizeMb': 65,
      'isDownloaded': true,
      'zoomRange': 'Zoom 10–16',
      'trailsCount': 4,
    },
    {
      'id': 'hai_van',
      'title': 'Đèo Hải Vân & Vườn QG Bạch Mã',
      'location': 'Đà Nẵng - Huế',
      'sizeMb': 82,
      'isDownloaded': false,
      'zoomRange': 'Zoom 10–16',
      'trailsCount': 8,
    },
    {
      'id': 'ta_nang',
      'title': 'Cung đường Tà Năng - Phan Dũng',
      'location': 'Lâm Đồng - Bình Thuận',
      'sizeMb': 95,
      'isDownloaded': false,
      'zoomRange': 'Zoom 10–16',
      'trailsCount': 3,
    },
    {
      'id': 'bidoup',
      'title': 'Vườn quốc gia Bidoup - Núi Bà',
      'location': 'Lạc Dương, Lâm Đồng',
      'sizeMb': 120,
      'isDownloaded': false,
      'zoomRange': 'Zoom 10–16',
      'trailsCount': 5,
    },
  ];

  String? _downloadingId;
  double _downloadProgress = 0.0;

  void _startDownload(String id) {
    setState(() {
      _downloadingId = id;
      _downloadProgress = 0.05;
    });

    // Giả lập tiến trình tải gạch bản đồ thực tế
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _downloadingId != id) return false;

      setState(() {
        _downloadProgress += 0.15;
      });

      if (_downloadProgress >= 1.0) {
        final pack = _mapPacks.firstWhere((p) => p['id'] == id);
        setState(() {
          pack['isDownloaded'] = true;
          _downloadingId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tải xong bản đồ "${pack['title']}" về máy!'),
            backgroundColor: AppTheme.safeColor,
          ),
        );
        return false;
      }
      return true;
    });
  }

  void _deletePack(String id) {
    final pack = _mapPacks.firstWhere((p) => p['id'] == id);
    setState(() {
      pack['isDownloaded'] = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xoá bộ nhớ đệm "${pack['title']}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1320),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'BẢN ĐỒ NGOẠI TUYẾN',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Bảng hiển thị dung lượng bộ nhớ đệm ─────────────
            _buildStorageCard(),
            const SizedBox(height: 24),

            // ── Tiêu đề danh sách ────────────────────────────────
            const Row(
              children: [
                Icon(Icons.terrain_rounded, color: AppTheme.safeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'CÁC KHU VỰC TREKKING ĐỀ XUẤT',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Danh sách gói bản đồ ─────────────────────────────
            ..._mapPacks.map((pack) => _buildMapPackCard(pack)).toList(),
            const SizedBox(height: 20),

            // ── Nút tải vùng toạ độ tuỳ chỉnh ────────────────────
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng quét vùng Bounding Box trên bản đồ đang sẵn sàng!')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.crop_free_rounded),
              label: const Text('Khoanh vùng toạ độ tuỳ chọn trên bản đồ để tải về'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    final percent = _usedStorageMb / _maxStorageMb;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sd_storage_rounded, color: AppTheme.safeColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'BỘ NHỚ ĐỆM BẢN ĐỒ NGOẠI TUYẾN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '${_usedStorageMb.toStringAsFixed(0)} / ${_maxStorageMb.toStringAsFixed(0)} MB',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 0.8 ? AppTheme.dangerColor : AppTheme.safeColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Giới hạn tối đa 500 MB để bảo vệ bộ nhớ máy. Bản đồ cũ sẽ tự động xoá nếu đầy.',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPackCard(Map<String, dynamic> pack) {
    final isDownloaded = pack['isDownloaded'] as bool;
    final isDownloading = _downloadingId == pack['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDownloaded ? AppTheme.safeColor.withAlpha(80) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDownloaded ? AppTheme.safeColor.withAlpha(30) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.map_rounded,
                  color: isDownloaded ? AppTheme.safeColor : Colors.white60,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack['title'] as String,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pack['location']} · ${pack['trailsCount']} cung đường · ${pack['sizeMb']} MB · ${pack['zoomRange']}',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.safeColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Đang tải gạch bản đồ: ${(_downloadProgress * 100).toInt()}%...',
              style: const TextStyle(color: AppTheme.safeColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ] else ...[
            Row(
              children: [
                if (isDownloaded) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.safeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.safeColor, size: 14),
                        const SizedBox(width: 4),
                        Text('Đã sẵn sàng Offline', style: TextStyle(color: AppTheme.safeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                    tooltip: 'Xoá khỏi bộ nhớ',
                    onPressed: () => _deletePack(pack['id'] as String),
                  ),
                ] else ...[
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _startDownload(pack['id'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text('Tải về (${pack['sizeMb']} MB)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
