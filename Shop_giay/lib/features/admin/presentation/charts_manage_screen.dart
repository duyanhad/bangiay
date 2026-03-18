import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/admin_models.dart';
import '../presentation/admin_controller.dart';
import '../widgets/admin_drawer.dart';

class ChartsManageScreen extends StatefulWidget {
  const ChartsManageScreen({super.key});

  @override
  State<ChartsManageScreen> createState() => _ChartsManageScreenState();
}

class _ChartsManageScreenState extends State<ChartsManageScreen> {
  String _selectedChartType = 'day';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminController>().loadStats(chartType: _selectedChartType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Thống kê doanh thu',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A4F7D), Color(0xFF2A7FB8)],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedChartType,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  style: const TextStyle(
                    color: Color(0xFF112131),
                    fontWeight: FontWeight.w700,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Theo ngày')),
                    DropdownMenuItem(value: 'month', child: Text('Theo tháng')),
                    DropdownMenuItem(value: 'year', child: Text('Theo năm')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedChartType = newValue;
                      });
                      context.read<AdminController>().loadStats(
                        chartType: newValue,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Consumer<AdminController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = controller.stats;
          if (stats == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                _buildOverview(stats),
                const SizedBox(height: 16),
                _buildRevenueChart(stats),
                const SizedBox(height: 20),
                _buildOrderStatusChart(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview(AdminStats stats) {
    final totalRevenue = stats.revenueChart.fold<num>(
      0,
      (sum, e) => sum + e.revenue,
    );

    final orderTotal =
        stats.pendingOrders +
        stats.confirmedOrders +
        stats.shippingOrders +
        stats.completedOrders +
        stats.cancelledOrders;

    final peak = stats.revenueChart.fold<ChartData?>(null, (current, next) {
      if (current == null) return next;
      return next.revenue > current.revenue ? next : current;
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E5A8C), Color(0xFF2C8CC8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D6D9D).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan nhanh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bộ lọc hiện tại: ${_filterLabel(_selectedChartType)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metricPill(
                icon: Icons.payments_rounded,
                label: 'Doanh thu',
                value: NumberFormat.compactCurrency(
                  locale: 'vi_VN',
                  symbol: '₫',
                  decimalDigits: 1,
                ).format(totalRevenue),
              ),
              _metricPill(
                icon: Icons.inventory_2_rounded,
                label: 'Đơn hàng',
                value: '$orderTotal đơn',
              ),
              _metricPill(
                icon: Icons.local_fire_department_rounded,
                label: 'Đỉnh doanh thu',
                value: peak == null
                    ? '0'
                    : '${peak.label}: ${NumberFormat.compact(locale: 'vi').format(peak.revenue)}đ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(AdminStats stats) {
    if (stats.revenueChart.isEmpty) {
      return _emptyCard('Chưa có dữ liệu doanh thu');
    }

    final spots = List<FlSpot>.generate(
      stats.revenueChart.length,
      (i) => FlSpot(i.toDouble(), stats.revenueChart[i].revenue / 1000000),
    );

    final maxYValue = spots.fold<double>(
      0,
      (maxVal, s) => math.max(maxVal, s.y),
    );
    final maxY = math.max(1.0, maxYValue * 1.25);
    final leftInterval = math.max(1.0, (maxY / 5).ceilToDouble());
    final labelStep = math.max(1, (stats.revenueChart.length / 8).ceil());

    final avgRevenue = stats.revenueChart.isEmpty
        ? 0
        : stats.revenueChart.fold<num>(0, (sum, e) => sum + e.revenue) /
              stats.revenueChart.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: Color(0xFF0E6A9C)),
              const SizedBox(width: 8),
              const Text(
                'Doanh thu theo thời gian',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'TB: ${NumberFormat.compact(locale: 'vi').format(avgRevenue)}đ',
                  style: const TextStyle(
                    color: Color(0xFF0E6A9C),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hiển thị ${_filterLabel(_selectedChartType).toLowerCase()}, trục Y: triệu đồng',
            style: TextStyle(
              color: Colors.blueGrey.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (stats.revenueChart.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 30,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            const FlLine(
                              color: Color(0xFF98B3C9),
                              strokeWidth: 1.5,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: const Color(0xFF0E6A9C),
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0D2233),
                    tooltipPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final index = touchedSpot.x.toInt();
                        if (index < 0 || index >= stats.revenueChart.length) {
                          return null;
                        }

                        final label = stats.revenueChart[index].label;
                        final exactRevenue = stats.revenueChart[index].revenue;

                        final formattedRevenue = NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: '₫',
                        ).format(exactRevenue);

                        return LineTooltipItem(
                          '$label\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: formattedRevenue,
                              style: const TextStyle(
                                color: Color(0xFF92E0FF),
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: leftInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFB7C8D7).withValues(alpha: 0.7),
                    strokeWidth: 1,
                    dashArray: const [6, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: leftInterval,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(value >= 10 ? 0 : 1)}M',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF48657A),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: labelStep.toDouble(),
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= stats.revenueChart.length) {
                          return const SizedBox();
                        }

                        final shouldShow =
                            index % labelStep == 0 ||
                            index == stats.revenueChart.length - 1;
                        if (!shouldShow) return const SizedBox();

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            stats.revenueChart[index].label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF42596D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: const Color(0xFF1A5D8C),
                    barWidth: 3.4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF3A90C7).withValues(alpha: 0.34),
                          const Color(0xFF3A90C7).withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart(AdminStats stats) {
    final data = [
      stats.pendingOrders,
      stats.confirmedOrders,
      stats.shippingOrders,
      stats.completedOrders,
      stats.cancelledOrders,
    ];

    if (data.every((e) => e == 0)) {
      return _emptyCard('Chưa có dữ liệu đơn hàng');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.donut_small_rounded, color: Color(0xFF0E6A9C)),
              SizedBox(width: 8),
              Text(
                'Trạng thái đơn hàng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 56,
                sections: [
                  _pieSection(stats.pendingOrders, const Color(0xFFF59E0B)),
                  _pieSection(stats.confirmedOrders, const Color(0xFF3B82F6)),
                  _pieSection(stats.shippingOrders, const Color(0xFFA855F7)),
                  _pieSection(
                    stats.completedOrders,
                    const Color(0xFF22C55E),
                    emphasize: true,
                  ),
                  _pieSection(stats.cancelledOrders, const Color(0xFFEF4444)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _legend(
                'Chờ xử lý',
                const Color(0xFFF59E0B),
                stats.pendingOrders,
              ),
              _legend(
                'Đã xác nhận',
                const Color(0xFF3B82F6),
                stats.confirmedOrders,
              ),
              _legend(
                'Đang giao',
                const Color(0xFFA855F7),
                stats.shippingOrders,
              ),
              _legend(
                'Hoàn thành',
                const Color(0xFF22C55E),
                stats.completedOrders,
              ),
              _legend('Đã hủy', const Color(0xFFEF4444), stats.cancelledOrders),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(
    int value,
    Color color, {
    bool emphasize = false,
  }) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: value == 0 ? '' : value.toString(),
      radius: emphasize ? 76 : 68,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }

  Widget _legend(String text, Color color, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$text: $value',
            style: const TextStyle(
              color: Color(0xFF243949),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: _cardStyle(),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF204D7A).withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _filterLabel(String type) {
    switch (type) {
      case 'month':
        return 'Theo tháng';
      case 'year':
        return 'Theo năm';
      default:
        return 'Theo ngày';
    }
  }
}
