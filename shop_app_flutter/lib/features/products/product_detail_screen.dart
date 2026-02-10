import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/styles/app_spacing.dart';
import '../../core/styles/app_text.dart';
import '../../core/network/api_client.dart';
import '../../core/network/endpoints.dart';
import '../cart/cart_provider.dart';
import '../cart/cart_item.dart';
import 'product_model.dart';
import 'product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? product;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    final api = context.read<ApiClient>();
    final res = await api.dio.get("${Endpoints.products}/${widget.productId}");

    setState(() {
      product = Product.fromJson(res.data);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy sản phẩm")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(product!.name)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: (product!.image != null && product!.image!.isNotEmpty)
                  ? ProductImage(url: product!.image!, fit: BoxFit.contain)
                  : const Icon(Icons.image, size: 120),
            ),
            const SizedBox(height: AppSpacing.gap16),
            Text(product!.name, style: AppText.h1),
            const SizedBox(height: 8),
            Text(
              "${product!.price.toStringAsFixed(0)} ₫",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Còn lại: ${product!.quantity}", style: AppText.muted),
            const SizedBox(height: AppSpacing.gap16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  cart.addItem(
                    CartItem(
                      productId: product!.id,
                      name: product!.name,
                      price: product!.price,
                      image: product!.image,
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đã thêm vào giỏ hàng")),
                  );
                },
                child: const Text("Thêm vào giỏ hàng"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
