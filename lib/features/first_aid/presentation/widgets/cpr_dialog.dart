import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// Hộp thoại Hồi sức tim phổi CPR Metronome
/// Chuẩn Hội Tim mạch: 110 nhịp/phút, tỷ lệ 30 ép tim : 2 thổi ngạt
class CprDialog extends StatefulWidget {
  const CprDialog({super.key});

  @override
  State<CprDialog> createState() => _CprDialogState();
}

class _CprDialogState extends State<CprDialog> with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  int _compressionCount = 0;
  int _cycleCount = 1;
  bool _isRescueBreathing = false;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 110 nhịp / phút = 545.45 ms / nhịp
  static const int _beatIntervalMs = 545;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _beatIntervalMs),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleCpr() {
    if (_isRunning) {
      _stopCpr();
    } else {
      _startCpr();
    }
  }

  void _startCpr() {
    setState(() {
      _isRunning = true;
      _isRescueBreathing = false;
    });
    _pulseController.repeat(reverse: true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: _beatIntervalMs), (timer) {
      if (_isRescueBreathing) return;

      HapticFeedback.lightImpact();
      setState(() {
        _compressionCount++;
        if (_compressionCount >= 30) {
          _triggerRescueBreathing();
        }
      });
    });
  }

  void _triggerRescueBreathing() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRescueBreathing = true;
      _compressionCount = 30;
    });
    _pulseController.stop();

    // 5 giây cho 2 lần thổi ngạt, sau đó tự động tiếp tục chu kỳ ép tim mới
    Timer(const Duration(seconds: 5), () {
      if (!mounted || !_isRunning) return;
      setState(() {
        _isRescueBreathing = false;
        _compressionCount = 0;
        _cycleCount++;
      });
      _pulseController.repeat(reverse: true);
    });
  }

  void _stopCpr() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _isRescueBreathing = false;
      _compressionCount = 0;
      _cycleCount = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B2232),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Tiêu đề & Đóng ─────────────────────────────
            Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppTheme.dangerColor, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'HỒI SỨC TIM PHỔI (CPR)',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // ── Vòng tròn nhịp tim Metronome ───────────────
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = _isRunning && !_isRescueBreathing ? _pulseAnimation.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRescueBreathing
                          ? Colors.blueAccent.withAlpha(40)
                          : AppTheme.dangerColor.withAlpha(40),
                      border: Border.all(
                        color: _isRescueBreathing ? Colors.blueAccent : AppTheme.dangerColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRescueBreathing ? Colors.blueAccent : AppTheme.dangerColor).withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isRescueBreathing) ...[
                            const Icon(Icons.air_rounded, color: Colors.blueAccent, size: 36),
                            const SizedBox(height: 4),
                            const Text(
                              'THỔI NGẠT',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const Text('2 LẦN', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 18)),
                          ] else ...[
                            Text(
                              '$_compressionCount',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              '/ 30 NHỊP',
                              style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Trạng thái chu kỳ ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Chu kỳ thứ $_cycleCount (110 nhịp / phút)',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // ── Chỉ dẫn y tế chuẩn ─────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Ép sâu: 5–6 cm giữa xương ức', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• Để lồng ngực nở hoàn toàn sau mỗi lần ép', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• Không dừng ép tim quá 10 giây', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Nút điều khiển ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _toggleCpr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.white24 : AppTheme.dangerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
                label: Text(
                  _isRunning ? 'TẠM DỪNG METRONOME' : 'BẮT ĐẦU ĐẬP NHỊP CPR',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
