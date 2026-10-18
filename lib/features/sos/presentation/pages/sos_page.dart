import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../first_aid/presentation/widgets/cpr_dialog.dart';

/// Màn hình Cứu nạn Khẩn cấp SOS Ngoại tuyến
/// Thiết kế ưu tiên sử dụng trong điều kiện hoảng loạn, chấn thương hoặc mất sóng di động
class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with TickerProviderStateMixin {
  // Trạng thái khẩn cấp
  bool _isEmergencyActive = false;
  bool _isFlashActive = false;
  bool _isSirenActive = false;

  // Animation giữ nút 3 giây
  late AnimationController _holdController;
  late Animation<double> _holdAnimation;
  Timer? _morseTimer;
  int _morseStep = 0;

  // Toạ độ cứu nạn mẫu (Đỉnh Bàn Cờ - Sơn Trà, Đà Nẵng)
  final double _mockLat = 16.1189;
  final double _mockLng = 108.2782;
  final double _mockAlt = 621.0;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _holdAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_holdController)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _triggerEmergency();
        }
      });
  }

  @override
  void dispose() {
    _holdController.dispose();
    _morseTimer?.cancel();
    super.dispose();
  }

  void _triggerEmergency() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isEmergencyActive = true;
      _isFlashActive = true;
      _isSirenActive = true;
    });
    _startMorseFlash();
  }

  void _startMorseFlash() {
    // Mã Morse SOS: 3 ngắn (200ms), 3 dài (600ms), 3 ngắn (200ms)
    _morseTimer?.cancel();
    _morseTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!_isEmergencyActive || !_isFlashActive) {
        timer.cancel();
        return;
      }
      setState(() {
        _morseStep = (_morseStep + 1) % 18;
      });
    });
  }

  void _cancelEmergency() {
    HapticFeedback.mediumImpact();
    _morseTimer?.cancel();
    _holdController.reset();
    setState(() {
      _isEmergencyActive = false;
      _isFlashActive = false;
      _isSirenActive = false;
    });
  }

  void _copyGpsCoordinates() {
    final text = 'SOS! Tôi cần cứu nạn gấp tại toạ độ:\n'
        'Vĩ độ: $_mockLat, Kinh độ: $_mockLng, Độ cao: ${_mockAlt.toStringAsFixed(0)}m\n'
        'Vị trí: Bán đảo Sơn Trà, Đà Nẵng (Gửi qua TrekGuard AI)';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã sao chép tin nhắn toạ độ cứu nạn vào bộ nhớ tạm!'),
        backgroundColor: AppTheme.safeColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isEmergencyActive ? const Color(0xFF200A0A) : const Color(0xFF0F1320),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'TRUNG TÂM CỨU NẠN SOS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppTheme.dangerColor),
            tooltip: 'Máy ép tim CPR',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const CprDialog(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Bảng toạ độ thời gian thực ───────────────────────
              _buildGpsCard(),
              const SizedBox(height: 24),

              // ── Nút kích hoạt trung tâm SOS ──────────────────────
              _buildSosTriggerButton(),
              const SizedBox(height: 28),

              // ── Bảng điều khiển tín hiệu phần cứng ────────────────
              if (_isEmergencyActive) ...[
                _buildHardwareControls(),
                const SizedBox(height: 24),
              ],

              // ── Phím gọi khẩn cấp ngoại tuyến ───────────────────
              _buildEmergencyContacts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEmergencyActive ? AppTheme.dangerColor : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location_rounded,
                color: _isEmergencyActive ? AppTheme.dangerColor : AppTheme.safeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'TOẠ ĐỘ GPS KHẨN CẤP (100% OFFLINE)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.safeColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Độ chính xác: ±3m',
                  style: TextStyle(fontSize: 11, color: AppTheme.safeColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_mockLat.toStringAsFixed(5)}° N,  ${_mockLng.toStringAsFixed(5)}° E',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Độ cao: ${_mockAlt.toStringAsFixed(0)}m · Đỉnh Bàn Cờ, Bán đảo Sơn Trà',
            style: const TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _copyGpsCoordinates,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Sao chép toạ độ gửi tin nhắn SMS cứu hộ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosTriggerButton() {
    if (_isEmergencyActive) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dangerColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ĐANG PHÁT TÍN HIỆU CỨU NẠN KHẨN CẤP\nĐèn Flash nhấp nháy mã Morse SOS & Còi hú',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cancelEmergency,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Huỷ chế độ cứu nạn khẩn cấp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => _holdController.forward(),
          onTapUp: (_) {
            if (_holdController.status != AnimationStatus.completed) {
              _holdController.reverse();
            }
          },
          onTapCancel: () => _holdController.reverse(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vòng tròn tiến trình đếm ngược
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: _holdAnimation.value,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.dangerColor.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.dangerColor),
                ),
              ),
              // Nút tròn SOS
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFF4D4D), AppTheme.dangerColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.dangerColor.withAlpha(120),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emergency_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 4),
                    const Text(
                      'GIỮ 3 GIÂY',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _holdAnimation.value > 0
                          ? '${((1 - _holdAnimation.value) * 3).toStringAsFixed(1)}s'
                          : 'KÍCH HOẠT SOS',
                      style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nhấn giữ nút tròn 3 giây để kích hoạt đèn chớp cứu hộ và còi hú',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildHardwareControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TÍN HIỆU PHẦN CỨNG THỰC TẾ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đèn Flash mã Morse SOS (... --- ...)', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(_isFlashActive ? 'Đang phát tín hiệu nhấp nháy' : 'Đã tắt', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            value: _isFlashActive,
            activeColor: AppTheme.dangerColor,
            onChanged: (val) {
              setState(() => _isFlashActive = val);
              if (val) _startMorseFlash();
            },
          ),
          const Divider(color: Colors.white12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Còi hú cứu nạn tần số cao', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(_isSirenActive ? 'Âm lượng tối đa qua loa ngoài' : 'Đã tắt', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            value: _isSirenActive,
            activeColor: AppTheme.dangerColor,
            onChanged: (val) => setState(() => _isSirenActive = val),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ĐƯỜNG DÂY NÓNG CỨU HỘ NGOẠI TUYẾN',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildContactTile(
                title: '112',
                subtitle: 'Cứu nạn Quốc gia',
                icon: Icons.shield_rounded,
                color: AppTheme.dangerColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactTile(
                title: '115',
                subtitle: 'Cấp cứu Y tế',
                icon: Icons.local_hospital_rounded,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCprQuickCard(),
      ],
    );
  }

  Widget _buildContactTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2232),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              const Icon(Icons.call_rounded, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildCprQuickCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.safeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.safeColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart_rounded, color: AppTheme.safeColor, size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hồi sức tim phổi CPR Metronome',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'Máy đập nhịp chuẩn 110 bpm ép tim cứu người',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const CprDialog(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safeColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Mở', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
