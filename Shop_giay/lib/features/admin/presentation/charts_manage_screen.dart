import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../widgets/admin_drawer.dart';
import '../data/admin_models.dart';
import '../presentation/admin_controller.dart';
import '../../../core/theme/admin_colors.dart';

class ChartsManageScreen extends StatefulWidget {
  const ChartsManageScreen({super.key});

  @override
  State<ChartsManageScreen> createState() => _ChartsManageScreenState();
}

class _ChartsManageScreenState extends State<ChartsManageScreen> {
  // Biến lưu trạng thái của bộ lọc thời gian
  String _selectedChartType = 'week';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminController>(context, listen: false).loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      
      // ==========================================
      // 1. APPBAR & BỘ LỌC THỜI GIAN
      // ==========================================
      appBar: AppBar(
        elevation: 0,
        title: const Text("Thống kê & Biểu đồ"),
        backgroundColor: AdminColors.header1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedChartType,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.filter_list, color: Colors.white),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text("7 ngày qua")),
                  DropdownMenuItem(value: 'month', child: Text("1 tháng qua")),
                  DropdownMenuItem(value: 'year', child: Text("1 năm qua")),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedChartType = newValue;
                    });
                    context
                        .read<AdminController>()
                        .loadStats(chartType: newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),

      // ==========================================
      // 2. MENU TRƯỢT BÊN TRÁI (DRAWER)
      // ==========================================
      drawer: const AdminDrawer(),

      body: Consumer<AdminController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = controller.stats;

          if (stats == null) {
            return const Center(child: Text("Không có dữ liệu"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildRevenueChart(stats),
                const SizedBox(height: 30),
                _buildOrderStatusChart(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  /// =====================================================
  /// 3. CHART DOANH THU (VUỐT/CHẠM CỰC NHẠY)
  /// =====================================================
  Widget _buildRevenueChart(AdminStats stats) {
    if (stats.revenueChart.isEmpty) {
      return _emptyCard("Chưa có dữ liệu doanh thu");
    }

    final spots = <FlSpot>[];

    for (int i = 0; i < stats.revenueChart.length; i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          stats.revenueChart[i].revenue / 1000000, // Đưa về đơn vị Triệu
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Doanh thu theo thời gian",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                
                // --- CẤU HÌNH CẢM ỨNG & TOOLTIP ---
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 50, // Tăng độ nhạy vùng chạm
                  
                  // Thanh gióng dọc và phóng to điểm khi vuốt
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        const FlLine(
                          color: Colors.blueGrey,
                          strokeWidth: 2,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: AdminColors.header1,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },

                  // Tooltip (Bong bóng hiển thị tiền)
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black87,
                    tooltipPadding: const EdgeInsets.all(8),
                    
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final index = touchedSpot.x.toInt();
                        if (index < 0 || index >= stats.revenueChart.length) {
                          return null;
                        }

                        final label = stats.revenueChart[index].label;
                        final exactRevenue = stats.revenueChart[index].revenue;

                        // Format thành tiền VNĐ
                        final formattedRevenue = NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: '₫',
                        ).format(exactRevenue);

                        return LineTooltipItem(
                          '$label\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: formattedRevenue,
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                // --- KẾT THÚC CẤU HÌNH CẢM ỨNG ---

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}M",
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, // Để là 1 để hiển thị đầy đủ nhãn trục X hơn
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();

                        if (index < 0 || index >= stats.revenueChart.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            stats.revenueChart[index].label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AdminColors.header1,
                    barWidth: 3,
                    
                    // HIỂN THỊ CÁC DẤU CHẤM TRÊN ĐƯỜNG
                    dotData: const FlDotData(show: true), 
                    
                    belowBarData: BarAreaData(
                      show: true,
                      color: AdminColors.header1.withOpacity(0.15),
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

  /// =====================================================
  /// 4. CHART TRẠNG THÁI ĐƠN HÀNG
  /// =====================================================
  Widget _buildOrderStatusChart(AdminStats stats) {
    final data = [
      stats.pendingOrders,
      stats.confirmedOrders,
      stats.shippingOrders,
      stats.completedOrders,
      stats.cancelledOrders,
    ];

    if (data.every((e) => e == 0)) {
      return _emptyCard("Chưa có dữ liệu đơn hàng");
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trạng thái đơn hàng",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  _pieSection(stats.pendingOrders, Colors.orange, "Chờ xử lý"),
                  _pieSection(stats.confirmedOrders, Colors.blue, "Đã xác nhận"),
                  _pieSection(stats.shippingOrders, Colors.purple, "Đang giao"),
                  _pieSection(stats.completedOrders, Colors.green, "Hoàn thành"),
                  _pieSection(stats.cancelledOrders, Colors.red, "Đã hủy"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _legend("Chờ xử lý", Colors.orange),
              _legend("Đã xác nhận", Colors.blue),
              _legend("Đang giao", Colors.purple),
              _legend("Hoàn thành", Colors.green),
              _legend("Đã hủy", Colors.red),
            ],
          )
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(int value, Color color, String title) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: value == 0 ? "" : value.toString(),
      radius: 70,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _legend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: _cardStyle(),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}