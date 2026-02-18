// lib/features/admin/data/admin_models.dart

class AdminStats {
  final int productCount;
  final int orderCount;
  final num revenue;
  final int totalStock;
  final int unansweredComments;
  final List<SimpleProduct> lowStock;
  final List<SimpleProduct> topSelling;

  AdminStats({
    required this.productCount,
    required this.orderCount,
    required this.revenue,
    required this.totalStock,
    this.unansweredComments = 0,
    required this.lowStock,
    required this.topSelling,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      // Sử dụng int.tryParse để an toàn nếu API trả về chuỗi "10" thay vì số 10
      productCount: int.tryParse(json['productCount']?.toString() ?? '0') ?? 0,
      orderCount: int.tryParse(json['orderCount']?.toString() ?? '0') ?? 0,
      revenue: num.tryParse(json['revenue']?.toString() ?? '0') ?? 0,
      totalStock: int.tryParse(json['totalStock']?.toString() ?? '0') ?? 0,
      unansweredComments: int.tryParse(json['unansweredComments']?.toString() ?? '0') ?? 0,
      
      // Map mảng an toàn
      lowStock: (json['lowStock'] as List? ?? [])
          .map((e) => SimpleProduct.fromJson(e))
          .toList(),
      topSelling: (json['topSelling'] as List? ?? [])
          .map((e) => SimpleProduct.fromJson(e))
          .toList(),
    );
  }
}

// Class phụ để hứng thông tin sản phẩm đơn giản
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
    return SimpleProduct(
      // MongoDB luôn trả về _id, map sang id của Dart
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sản phẩm không tên',
      
      // Parse số an toàn tuyệt đối
      stock: _parseStock(json),
      soldCount: int.tryParse(json['soldCount']?.toString() ?? json['sold']?.toString() ?? '0') ?? 0,
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      
      // Xử lý ảnh: Đảm bảo luôn là List<String>, loại bỏ null
      images: (json['images'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty) // Lọc bỏ chuỗi rỗng
          .toList(),
    );
  }

  // Hàm phụ xử lý stock thông minh
  static int _parseStock(Map<String, dynamic> json) {
    // 1. Ưu tiên lấy trực tiếp nếu backend trả về số
    if (json['stock'] != null) {
      return int.tryParse(json['stock'].toString()) ?? 0;
    }
    
    // 2. Dự phòng field totalStock
    if (json['totalStock'] != null) {
      return int.tryParse(json['totalStock'].toString()) ?? 0;
    }

    // 3. Nếu backend trả về mảng variants/sizes, tự cộng dồn
    // (Phòng trường hợp cấu trúc thay đổi trong tương lai)
    if (json['sizes'] != null && json['sizes'] is List) {
      int sum = 0;
      for (var s in json['sizes']) {
        // Cộng dồn qty an toàn
        sum += int.tryParse(s['qty']?.toString() ?? '0') ?? 0;
      }
      return sum;
    }
    
    return 0;
  }
}