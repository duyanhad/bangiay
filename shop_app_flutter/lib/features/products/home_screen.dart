import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/styles/app_spacing.dart';
import '../../core/styles/app_text.dart';
import 'product_provider.dart';
import 'product_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    provider.loadBrands();
    provider.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bán Giày"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.go("/cart"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Danh mục", style: AppText.h2),
            const SizedBox(height: AppSpacing.gap12),

            // BRANDS
            SizedBox(
              height: 40,
              child: provider.brands.isEmpty
                  ? const Center(child: Text("Đang tải..."))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text("Tất cả"),
                            selected: provider.selectedBrand == null,
                            onSelected: (_) => provider.loadProducts(),
                          ),
                        ),
                        ...provider.brands.map((b) {
                          final active = b == provider.selectedBrand;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(b),
                              selected: active,
                              onSelected: (_) => provider.loadProducts(brand: b),
                            ),
                          );
                        }),
                      ],
                    ),
            ),

            const SizedBox(height: AppSpacing.gap16),

            Expanded(
              child: provider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.products.isEmpty
                      ? const Center(child: Text("Không có sản phẩm"))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: provider.products.length,
                          itemBuilder: (_, i) {
                            final p = provider.products[i];

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.go("/product/${p.id}"),
                              child: Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: (p.image != null && p.image!.isNotEmpty)
                                          ? ProductImage(
                                              url: p.image!,
                                              fit: BoxFit.cover,
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(Icons.image, size: 80),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "${p.price.toStringAsFixed(0)} ₫",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            )
          ],
        ),
      ),
    );
  }
}
