// lib/features/admin/data/admin_models.dart

import 'package:flutter/foundation.dart';

/// ==============================
/// 1. ChartData (Dữ liệu biểu đồ)
/// ==============================
class ChartData {
  final String label;
  final double revenue;

  ChartData({
    required this.label,
    required this.revenue,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label']?.toString() ??
          json['_id']?.toString() ??
          json['date']?.toString() ??
          'N/A',
      revenue: double.tryParse(
              json['revenue']?.toString() ??
              json['total']?.toString() ??
              '0') ??
          0.0,
    );
  }
}

/// =====================================
/// 2. AdminStats (Toàn bộ dữ liệu dashboard)
/// =====================================
class AdminStats {
  final int productCount;
  final int orderCount;
  final num revenue;
  final int totalStock;
  final int unansweredComments;

  /// 🔵 THÊM TRẠNG THÁI ĐƠN HÀNG
  final int pendingOrders;
  final int confirmedOrders;
  final int shippingOrders;
  final int completedOrders;
  final int cancelledOrders;

  final List<SimpleProduct> lowStock;
  final List<SimpleProduct> topSelling;
  final List<ChartData> revenueChart;

  AdminStats({
    required this.productCount,
    required this.orderCount,
    required this.revenue,
    required this.totalStock,
    this.unansweredComments = 0,

    /// trạng thái đơn
    this.pendingOrders = 0,
    this.confirmedOrders = 0,
    this.shippingOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,

    required this.lowStock,
    required this.topSelling,
    required this.revenueChart,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    List<T> _parseList<T>(
        dynamic list, T Function(Map<String, dynamic>) fromJson) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => fromJson(e))
            .toList();
      }
      return [];
    }

    return AdminStats(
      productCount:
          int.tryParse(json['productCount']?.toString() ?? '0') ?? 0,
      orderCount:
          int.tryParse(json['orderCount']?.toString() ?? '0') ?? 0,
      revenue:
          num.tryParse(json['revenue']?.toString() ?? '0') ?? 0,
      totalStock:
          int.tryParse(json['totalStock']?.toString() ?? '0') ?? 0,
      unansweredComments:
          int.tryParse(json['unansweredComments']?.toString() ?? '0') ?? 0,

      /// trạng thái đơn
      pendingOrders:
          int.tryParse(json['pendingOrders']?.toString() ?? '0') ?? 0,
      confirmedOrders:
          int.tryParse(json['confirmedOrders']?.toString() ?? '0') ?? 0,
      shippingOrders:
          int.tryParse(json['shippingOrders']?.toString() ?? '0') ?? 0,
      completedOrders:
          int.tryParse(json['completedOrders']?.toString() ?? '0') ?? 0,
      cancelledOrders:
          int.tryParse(json['cancelledOrders']?.toString() ?? '0') ?? 0,

      lowStock: _parseList(json['lowStock'], SimpleProduct.fromJson),
      topSelling: _parseList(json['topSelling'], SimpleProduct.fromJson),
      revenueChart:
          _parseList(json['revenueChart'], ChartData.fromJson),
    );
  }
}

/// =====================================
/// 3. SimpleProduct
/// =====================================
class SimpleProduct {
  final String id;
  final String name;
  final int stock;
  final int soldCount;
  final num price;
  final List<String> images;

  SimpleProduct({
    required this.id,
    required this.name,
    this.stock = 0,
    this.soldCount = 0,
    this.price = 0,
    required this.images,
  });

  factory SimpleProduct.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> pData = json;

    final keysToSearch = ['product', 'productInfo', 'details'];

    for (var key in keysToSearch) {
      if (json[key] != null) {
        if (json[key] is List && (json[key] as List).isNotEmpty) {
          pData = json[key][0];
          break;
        } else if (json[key] is Map<String, dynamic>) {
          pData = json[key];
          break;
        }
      }
    }

    Set<String> imageSet = {};

    if (pData['images'] is List) {
      for (var img in pData['images']) {
        if (img != null) imageSet.add(img.toString());
      }
    }

    if (pData['image_url'] != null) {
      imageSet.add(pData['image_url'].toString());
    }

    if (pData['imageUrl'] != null) {
      imageSet.add(pData['imageUrl'].toString());
    }

    if (pData['image'] != null && pData['image'] is String) {
      imageSet.add(pData['image'].toString());
    }

    List<String> finalImages = imageSet
        .where((e) =>
            e.isNotEmpty && e != "null" && e.startsWith('http'))
        .toList();

    return SimpleProduct(
      id: json['_id']?.toString() ??
          pData['_id']?.toString() ??
          '',
      name: pData['name']?.toString() ??
          'Sản phẩm không tên',
      stock: _parseStock(pData),
      soldCount: int.tryParse(
              json['totalSold']?.toString() ??
                  json['count']?.toString() ??
                  json['sold']?.toString() ??
                  pData['sold']?.toString() ??
                  '0') ??
          0,
      price: num.tryParse(pData['price']?.toString() ?? '0') ?? 0,
      images: finalImages,
    );
  }

  static int _parseStock(Map<String, dynamic> data) {
    try {
      if (data['stock'] != null) {
        return int.tryParse(data['stock'].toString()) ?? 0;
      }

      if (data['totalStock'] != null) {
        return int.tryParse(data['totalStock'].toString()) ?? 0;
      }

      if (data['sizes'] != null && data['sizes'] is List) {
        return (data['sizes'] as List).fold<int>(0, (sum, s) {
          final qty = int.tryParse(
                  s['qty']?.toString() ??
                      s['quantity']?.toString() ??
                      '0') ??
              0;
          return sum + qty;
        });
      }
    } catch (e) {
      debugPrint("Error parsing stock: $e");
    }

    return 0;
  }
}