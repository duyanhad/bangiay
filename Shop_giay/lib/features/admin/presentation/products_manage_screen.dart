import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/admin_colors.dart';
import '../widgets/admin_drawer.dart';

class ProductsManageScreen extends StatefulWidget {
  const ProductsManageScreen({super.key});

  @override
  State<ProductsManageScreen> createState() => _ProductsManageScreenState();
}

class _ProductsManageScreenState extends State<ProductsManageScreen> {
  // Dữ liệu giả (Dummy Data)
  final List<Map<String, dynamic>> _products = [
    {"id": 1, "name": "iPhone 15 Pro Max", "price": 32000000, "stock": 5, "image": "https://via.placeholder.com/150"},
    {"id": 2, "name": "Samsung Galaxy S24", "price": 28000000, "stock": 12, "image": "https://via.placeholder.com/150"},
    {"id": 3, "name": "MacBook Air M2", "price": 24000000, "stock": 0, "image": "https://via.placeholder.com/150"},
    {"id": 4, "name": "Sony XM5 Headphone", "price": 8500000, "stock": 20, "image": "https://via.placeholder.com/150"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text("Quản lý Sản phẩm"),
        backgroundColor: AdminColors.header1,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AdminColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // TODO: Chuyển sang màn hình thêm sản phẩm
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng thêm sản phẩm")));
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final p = _products[index];
          final isOutStock = p['stock'] == 0;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(image: NetworkImage(p['image']), fit: BoxFit.cover),
                  color: Colors.grey[200]
                ),
              ),
              title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(NumberFormat.currency(locale: 'vi', symbol: '₫').format(p['price']),
                      style: const TextStyle(color: AdminColors.header1, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 14, color: isOutStock ? Colors.red : Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        isOutStock ? "Hết hàng" : "Kho: ${p['stock']}",
                        style: TextStyle(color: isOutStock ? Colors.red : Colors.green, fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}