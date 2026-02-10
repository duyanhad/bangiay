class Product {
  final String id;
  final String name;
  final double price;
  final String? image; // URL ảnh
  final int quantity;
  final String brand;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.brand,
    this.image,
  });

  static String _asString(dynamic v, {String fallback = ""}) {
    if (v == null) return fallback;
    return v.toString();
  }

  static double _asDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = _asString(json['_id'] ?? json['id'] ?? json['productId']);
    final name = _asString(json['name'] ?? json['title'], fallback: "(No name)");
    final brand = _asString(json['brand'], fallback: "");

    // ✅ FIX: backend/db của bạn dùng image_url
    final image = (json['image_url'] ??
            json['image'] ??
            json['imageUrl'] ??
            json['thumbnail'])
        ?.toString();

    final quantity =
        _asInt(json['quantity'] ?? json['qty'] ?? json['stock'], fallback: 0);

    // ✅ Ưu tiên final_price nếu có
    final price = _asDouble(json['final_price'] ?? json['price'], fallback: 0);

    return Product(
      id: id.isEmpty ? "UNKNOWN_ID" : id,
      name: name,
      price: price,
      quantity: quantity,
      brand: brand,
      image: image,
    );
  }
}
