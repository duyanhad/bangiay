class CartItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final String size; // ✅ Đổi từ selectedSize thành size để khớp với CartScreen

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.size, // ✅ Cập nhật ở đây
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
      // ✅ Lấy key 'size' từ JSON mà Backend trả về
      size: (json['size'] ?? '').toString(), 
    );
  }
}