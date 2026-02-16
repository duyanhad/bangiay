class AdminStats {
  final int orderCount;
  final int productCount;
  final int userCount;
  final int totalStock;
  final int lowStock;
  final String topSelling;
  final double revenue;

  AdminStats({
    required this.orderCount,
    required this.productCount,
    required this.userCount,
    required this.totalStock,
    required this.lowStock,
    required this.topSelling,
    required this.revenue,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      orderCount: json['orderCount'] ?? 0,
      productCount: json['productCount'] ?? 0,
      userCount: json['userCount'] ?? 0,
      totalStock: json['totalStock'] ?? 0,
      lowStock: json['lowStock'] ?? 0,
      topSelling: json['topSelling'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}
