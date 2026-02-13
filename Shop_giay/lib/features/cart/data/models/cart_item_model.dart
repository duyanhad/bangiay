class CartItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final String selectedSize; // 👈 Thêm trường này

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.selectedSize, // 👈 Cập nhật constructor
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    String imageUrl = product['image_url'] ?? product['image'] ?? '';

    return CartItem(
      id: json['_id'] ?? '',
      productId: product['_id'] ?? '', 
      name: product['name'] ?? 'Sản phẩm không tên',
      image: imageUrl, 
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      selectedSize: (json['size'] ?? '40').toString(), // 👈 Lấy size từ JSON của Backend
    );
  }
}