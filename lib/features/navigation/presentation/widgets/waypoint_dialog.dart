import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/navigation_entities.dart';

/// Hộp thoại Tạo Điểm Mốc (Waypoint) trên bản đồ ngoại tuyến
class WaypointDialog extends StatefulWidget {
  final GpsPoint currentPosition;
  final Function(WaypointEntity waypoint)? onSave;

  const WaypointDialog({
    super.key,
    required this.currentPosition,
    this.onSave,
  });

  @override
  State<WaypointDialog> createState() => _WaypointDialogState();
}

class _WaypointDialogState extends State<WaypointDialog> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'water';

  final List<({String id, String label, IconData icon, Color color})> _categories = [
    (id: 'water', label: 'Nguồn nước', icon: Icons.water_drop_rounded, color: Colors.blueAccent),
    (id: 'camp', label: 'Cắm trại', icon: Icons.cabin_rounded, color: AppTheme.safeColor),
    (id: 'danger', label: 'Nguy hiểm', icon: Icons.warning_rounded, color: AppTheme.dangerColor),
    (id: 'viewpoint', label: 'Ngắm cảnh', icon: Icons.camera_alt_rounded, color: Colors.purpleAccent),
    (id: 'shelter', label: 'Trú ẩn', icon: Icons.roofing_rounded, color: Colors.orangeAccent),
    (id: 'summit', label: 'Đỉnh núi', icon: Icons.landscape_rounded, color: Colors.tealAccent),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên điểm mốc!')),
      );
      return;
    }

    final newWaypoint = WaypointEntity(
      id: const Uuid().v4(),
      tripId: 'active_trip',
      name: name,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      position: widget.currentPosition,
      synced: false,
    );

    widget.onSave?.call(newWaypoint);
    Navigator.of(context).pop(newWaypoint);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B2232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tiêu đề ──────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.add_location_alt_rounded, color: AppTheme.safeColor, size: 26),
                const SizedBox(width: 10),
                const Text(
                  'TẠO ĐIỂM MỐC (WAYPOINT)',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // ── Toạ độ GPS hiện tại ───────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, color: AppTheme.safeColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.currentPosition.latitude.toStringAsFixed(5)}, ${widget.currentPosition.longitude.toStringAsFixed(5)}'
                      '${widget.currentPosition.altitude != null ? ' (${widget.currentPosition.altitude!.toStringAsFixed(0)}m)' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tên điểm mốc ─────────────────────────────────
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tên điểm mốc *',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'VD: Nguồn nước suối trong, Bãi hạ trại...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.safeColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Chọn danh mục ────────────────────────────────
            const Text(
              'Loại điểm mốc',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.id;
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.black : cat.color),
                  label: Text(cat.label),
                  selected: isSelected,
                  selectedColor: cat.color,
                  backgroundColor: Colors.white10,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Ghi chú thêm ─────────────────────────────────
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'VD: Nước chảy quanh năm, cần lọc trước khi uống...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // ── Nút Lưu ──────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.safeColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('LƯU ĐIỂM MỐC NGOẠI TUYẾN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
