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
      productCount: json['productCount'] ?? 0,
      orderCount: json['orderCount'] ?? 0,
      revenue: json['revenue'] ?? 0,
      totalStock: json['totalStock'] ?? 0,
      unansweredComments: json['unansweredComments'] ?? 0,
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
  final List<String> images; // ✅ ĐÃ THÊM TRƯỜNG NÀY

  SimpleProduct({
    required this.id,
    required this.name,
    this.stock = 0,
    this.soldCount = 0,
    this.price = 0,
    required this.images, // ✅ Bắt buộc có images
  });

  factory SimpleProduct.fromJson(Map<String, dynamic> json) {
    return SimpleProduct(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Không tên',
      stock: _parseStock(json), // Dùng hàm phụ để tính stock an toàn
      soldCount: json['sold'] ?? json['soldCount'] ?? 0,
      price: json['price'] ?? 0,
      // ✅ Map dữ liệu ảnh từ JSON
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  // Hàm phụ xử lý stock (phòng trường hợp API trả về mảng sizes thay vì số int)
  static int _parseStock(Map<String, dynamic> json) {
    if (json['stock'] != null) return json['stock']; // Nếu có sẵn stock
    if (json['totalStock'] != null) return json['totalStock']; // Hoặc totalStock
    
    // Nếu trả về mảng sizes (S, M, L...), cộng dồn lại
    if (json['sizes'] != null && json['sizes'] is List) {
      int sum = 0;
      for (var s in json['sizes']) {
        sum += (s['qty'] ?? 0) as int;
      }
      return sum;
    }
    return 0;
  }
}