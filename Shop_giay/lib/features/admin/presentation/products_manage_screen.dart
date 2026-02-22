  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:provider/provider.dart';

  import '../../../core/theme/admin_colors.dart';
  import '../../../core/config/app_config.dart';
  import '../widgets/admin_drawer.dart';
  import '../presentation/admin_controller.dart';
  import 'package:flutter/services.dart';
  
  class ProductsManageScreen extends StatefulWidget {
    const ProductsManageScreen({super.key});

    @override
    State<ProductsManageScreen> createState() =>
        _ProductsManageScreenState();
  }

  class _ProductsManageScreenState
      extends State<ProductsManageScreen> {
    final TextEditingController _searchCtrl =
        TextEditingController();

    @override
    void initState() {
      super.initState();
      Future.microtask(
        () => context.read<AdminController>().loadProducts(),
      );
    }

    // ================= IMAGE URL FIX =================
    String _getValidImageUrl(Map p) {
      final imageUrl = p['image_url'];

      if (imageUrl == null) return "";

      if (imageUrl.toString().startsWith('http')) {
        return imageUrl;
      }

      String base = AppConfig.baseUrl;

      if (base.contains('localhost')) {
        base = base.replaceFirst('localhost', '10.0.2.2');
      }

      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }

      return "$base/$imageUrl";
    }

    // ================= DELETE CONFIRM =================
    void _confirmDelete(
      
        BuildContext context, String id, String name) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text("Xác nhận xóa"),
          content: Text("Bạn muốn xóa '$name'?"),
          actions: [
            TextButton(
              onPressed: ()  => Navigator.pop(ctx),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);

                final ok =
                    await context.read<AdminController>()
                        .deleteProduct(id);

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? "Đã xóa sản phẩm"
                        : "Xóa thất bại"),
                    backgroundColor:
                        ok ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text(
                "Xóa",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    // ================= MODERN ADD / EDIT DIALOG =================
void _showProductDialog({Map? product}) {
  final nameCtrl =
      TextEditingController(text: product?['name'] ?? '');
  final priceCtrl =
      TextEditingController(
          text: (product?['price'] ?? '').toString());
  final imageCtrl =
      TextEditingController(text: product?['image_url'] ?? '');

final descCtrl =
    TextEditingController(text: product?['description'] ?? '');

  final isEdit = product != null;

  String id = '';
  if (product != null) {
    if (product['_id'] is Map &&
        product['_id']['\$oid'] != null) {
      id = product['_id']['\$oid'];
    } else if (product['_id'] is String) {
      id = product['_id'];
    }
  }

  // ===== VARIANTS LIST =====
  List<Map<String, dynamic>> variants = [];

  if (product != null && product['variants'] is List) {
    variants = List<Map<String, dynamic>>.from(
        product['variants']);
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
         int totalStock = variants.fold<int>(
  0,
  (sum, v) =>
      sum + (int.tryParse(v['stock']?.toString() ?? '0') ?? 0),
);

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 750,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ===== HEADER =====
                    Row(
                      children: [
                        Icon(
                          isEdit
                              ? Icons.edit
                              : Icons.add,
                          color:
                              const Color.fromARGB(255, 241, 241, 241),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit
                              ? "Chỉnh sửa sản phẩm"
                              : "Thêm sản phẩm",
                          style:
                              const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(
                                  context),
                          icon: const Icon(
                              Icons.close),
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ===== BASIC INFO =====
                    Row(
                      children: [
                        Expanded(
                            child: _modernField(
                                "Tên sản phẩm",
                                nameCtrl,
                                Icons.shopping_bag)),
                        const SizedBox(width: 20),
                        Expanded(
                            child: _modernField(
                                "Giá",
                                priceCtrl,
                                Icons.attach_money,
                                isNumber: true)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _modernField("URL hình ảnh",
                        imageCtrl, Icons.image),
                        const SizedBox(height: 20),

TextField(
  controller: descCtrl,
  maxLines: 4,
  decoration: InputDecoration(
    labelText: "Mô tả sản phẩm",
    alignLabelWithHint: true,
    prefixIcon: const Icon(Icons.description),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: AdminColors.header1,
        width: 2,
      ),
    ),
  ),
),

                    const SizedBox(height: 30),

                    // ===== SIZE SECTION =====
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          "Quản lý Size & Kho",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 202, 213, 222),
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              variants.add({
                                "size": 42,
                                "stock": 0
                              });
                            });
                          },
                          icon:
                              const Icon(Icons.add),
                          label:
                              const Text("Thêm size"),
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    ...variants
                        .asMap()
                        .entries
                        .map((entry) {
                      int index = entry.key;
                      var v = entry.value;

                      final sizeCtrl =
                          TextEditingController(
                              text: v['size']
                                  .toString());
                      final stockCtrl =
                          TextEditingController(
                              text: v['stock']
                                  .toString());

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                                bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                    sizeCtrl,
                                keyboardType:
                                    TextInputType
                                        .number,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      "Size",
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  v['size'] =
                                      int.tryParse(
                                              val) ??
                                          0;
                                },
                              ),
                            ),
                            const SizedBox(
                                width: 12),
                            Expanded(
                              child: TextField(
                                controller:
                                    stockCtrl,
                                keyboardType:
                                    TextInputType
                                        .number,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      "Số lượng",
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  v['stock'] =
                                      int.tryParse(
                                              val) ??
                                          0;
                                  setStateDialog(
                                      () {});
                                },
                              ),
                            ),
                            const SizedBox(
                                width: 10),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete,
                                  color:
                                      Colors.red),
                              onPressed: () {
                                setStateDialog(
                                    () {
                                  variants
                                      .removeAt(
                                          index);
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 15),

                    // ===== TOTAL STOCK =====
                    Container(
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue
                            .withOpacity(.1),
                        borderRadius:
                            BorderRadius.circular(
                                12),
                      ),
                      child: Text(
                        "Tổng kho: $totalStock",
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // ===== ACTIONS =====
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(
                                  context),
                          child:
                              const Text("Hủy"),
                        ),
                        const SizedBox(
                            width: 16),
                        ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                AdminColors.header1,
                          ),
                          onPressed: () async {
                            final controller =
                                context.read<
                                    AdminController>();

                            final data = {
  "name": nameCtrl.text.trim(),
  "price": int.tryParse(priceCtrl.text) ?? 0,
  "image_url": imageCtrl.text.trim(),
  "description": descCtrl.text.trim(),
  "variants": variants,
};

                            bool success;

                            if (isEdit) {
                              success =
                                  await controller
                                      .updateProduct(
                                          id,
                                          data);
                            } else {
                              success =
                                  await controller
                                      .createProduct(
                                          data);
                            }

                            if (!mounted)
                              return;

                            Navigator.pop(
                                context);

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                    success
                                        ? "Thành công"
                                        : "Thất bại"),
                                backgroundColor:
                                    success
                                        ? Colors
                                            .green
                                        : Colors
                                            .red,
                              ),
                            );
                          },
                          child: Text(isEdit
                              ? "Cập nhật"
                              : "Thêm sản phẩm"),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  // ================= MODERN INPUT FIELD =================
  Widget _modernField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          isNumber ? TextInputType.number : null,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: AdminColors.header1,
              width: 2),
        ),
      ),
    );
  }

    // ================= SIZE STOCK UI =================
    Widget _buildSizeStock(Map p) {
  final variants = p['variants'];

  if (variants == null || variants is! List) {
    return const SizedBox();
  }

  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Wrap(
      spacing: 6,
      runSpacing: 4,
      children: variants.map<Widget>((v) {
        final size = v['size'] ?? '';
        final qty = v['stock'] ?? 0;

        Color bg;
        Color textColor;

        if (qty <= 0) {
          bg = Colors.red.withOpacity(.15);
          textColor = Colors.red;
        } else if (qty <= 5) {
          bg = Colors.orange.withOpacity(.15);
          textColor = Colors.orange;
        } else {
          bg = Colors.green.withOpacity(.15);
          textColor = Colors.green;
        }

        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Size $size ($qty)",
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    ),
  );
}

    // ================= PRODUCT CARD =================
    Widget _productCard(Map p) {
      // FIX $oid
      String id = '';
      if (p['_id'] is Map &&
          p['_id']['\$oid'] != null) {
        id = p['_id']['\$oid'];
      } else if (p['_id'] is String) {
        id = p['_id'];
      }

      final name = p['name'] ?? '';
      final price =
          p['final_price'] ?? p['price'] ?? 0;
      final stock = p['stock'] ?? 0;
      final imgUrl = _getValidImageUrl(p);

      Color stockColor;
      if (stock <= 0) {
        stockColor = Colors.red;
      } else if (stock <= 20) {
        stockColor = Colors.orange;
      } else {
        stockColor = Colors.green;
      }

      return Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),

          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: imgUrl.isEmpty
                  ? const Icon(Icons.image_not_supported)
                  : Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
            ),
          ),

          title: Text(
            name,
            style: const TextStyle(
                fontWeight: FontWeight.bold),
          ),

          subtitle: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              Text(
                NumberFormat.currency(
                        locale: 'vi', symbol: '₫')
                    .format(price),
                style: const TextStyle(
                  color: AdminColors.header1,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Chip(
                label: Text("Tổng kho: $stock"),
                backgroundColor:
                    stockColor.withOpacity(.15),
                labelStyle: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.bold),
              ),

              _buildSizeStock(p),
            ],
          ),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            IconButton(
    icon: const Icon(Icons.edit,
        color: Colors.blue),
    onPressed: () =>
        _showProductDialog(product: p),
  ),
              IconButton(
                icon: const Icon(Icons.delete,
                    color: Colors.red),
                onPressed: () =>
                    _confirmDelete(context, id, name),
              ),
            ],
          ),
        ),
      );
    }

    // ================= UI =================
    @override
    Widget build(BuildContext context) {
      final controller =
          context.watch<AdminController>();

      return Scaffold(
        backgroundColor: AdminColors.bg,
        drawer: const AdminDrawer(),
        appBar: AppBar(
          title: const Text("Quản lý sản phẩm"),
          backgroundColor: AdminColors.header1,
          foregroundColor: Colors.white,
        ),
        floatingActionButton:
            FloatingActionButton.extended(
          elevation: 6,
          backgroundColor: AdminColors.header1,
          icon: const Icon(Icons.add,
              color: Colors.white),
          label: const Text(
            "Thêm sản phẩm",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () => _showProductDialog(),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              controller.loadProducts(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Tìm sản phẩm...",
                    prefixIcon:
                        const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    context
                        .read<AdminController>()
                        .searchProducts(v);
                  },
                ),
              ),
              Expanded(
                child: controller.isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator())
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6),
                        itemCount: controller
                            .products.length,
                        itemBuilder: (_, i) =>
                            _productCard(
                                controller.products[i]),
                      ),
              ),
            ],
          ),
        ),
      );
    }
  }
