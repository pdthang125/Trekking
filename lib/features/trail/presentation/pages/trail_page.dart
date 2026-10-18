import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Trail management — Altitude Profile + Waypoints
class TrailPage extends StatelessWidget {
  const TrailPage({super.key});

  // Mock data — replace with real GPS tracklog from Drift
  static final _altitudeData = [
    const FlSpot(0, 1200),
    const FlSpot(1, 1380),
    const FlSpot(2, 1520),
    const FlSpot(3, 1650),
    const FlSpot(4, 1800),
    const FlSpot(5, 1920),
    const FlSpot(6, 2100),
    const FlSpot(7, 2350),
    const FlSpot(8, 2500),
    const FlSpot(9, 2750),
    const FlSpot(10, 3143),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('🏔️ Lộ Trình & Độ Cao')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats Row ────────────────────────────────────────
            Row(
              children: [
                _StatCard(label: 'Khoảng cách', value: '8.4 km', icon: Icons.straighten_rounded),
                const SizedBox(width: 12),
                _StatCard(label: 'Độ cao tối đa', value: '3,143 m', icon: Icons.terrain_rounded),
                const SizedBox(width: 12),
                _StatCard(label: 'Thời gian', value: '6h 20p', icon: Icons.timer_rounded),
              ],
            ),
            const SizedBox(height: 24),

            // ── Altitude Profile Chart ───────────────────────────
            Text(
              'Đồ thị độ cao (Altitude Profile)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 10,
                      minY: 1000,
                      maxY: 3500,
                      gridData: FlGridData(
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.colorScheme.outline.withAlpha(50),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (val, meta) => Text(
                              '${val.toInt()}m',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) => Text(
                              '${val.toInt()}km',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _altitudeData,
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withAlpha(40),
                          ),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Waypoints List ──────────────────────────────────
            Text('Điểm mốc (Waypoints)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _WaypointsList(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(height: 6),
              Text(value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaypointsList extends StatelessWidget {
  final _mockWaypoints = const [
    (name: 'Điểm xuất phát', alt: '1200m', time: '07:00'),
    (name: 'Trạm nghỉ 1', alt: '1800m', time: '09:30'),
    (name: 'Đỉnh Fansipan', alt: '3143m', time: '13:20'),
  ];

  const _WaypointsList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mockWaypoints.length,
      itemBuilder: (_, i) {
        final wp = _mockWaypoints[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('${i + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(wp.name, style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text('Độ cao: ${wp.alt}'),
            trailing: Text(wp.time,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
