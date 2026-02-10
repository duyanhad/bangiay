class CartItem {
  final String productId;
  final String name;
  final double price;
  final String? image;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.image,
    this.qty = 1,
  });
}
