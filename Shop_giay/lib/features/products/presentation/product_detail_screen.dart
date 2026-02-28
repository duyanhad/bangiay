  import 'package:flutter/material.dart';
  import '../data/product_api.dart';
  import '../domain/product_model.dart';
  import '../../cart/data/cart_api.dart';
  import '../../cart/data/cart_repository.dart';
  import '../../cart/presentation/cart_screen.dart';
  import 'package:dio/dio.dart';
  import '../../../core/config/app_config.dart';
  
// Đường dẫn tới file CommentApi
  
  import 'package:shop_giay/features/comments/presentation/product_comment_section.dart';
   // Đường dẫn tới file model Comment
  
  
    class ProductDetailScreen extends StatefulWidget {
    final Product? product;
    final String? productId;

    const ProductDetailScreen({
      super.key,
      this.product,
      this.productId,
    }) : assert(product != null || productId != null, 'product or productId is required');

    @override
    State<ProductDetailScreen> createState() => _ProductDetailScreenState();
  }

  class _ProductDetailScreenState extends State<ProductDetailScreen> {
      bool _isAdding = false; 
    final _api = ProductApi();
    
    final _cartRepo = CartRepository(
    CartApi(
      Dio(BaseOptions(baseUrl: AppConfig.baseUrl)),
    ),
    
  );


    Future<Product>? _future;

    int _selectedImage = 0;
    String? _selectedSize;
    int _qty = 1;
    int _maxStock = 999;

    @override
    void initState() {
      super.initState();
      if (widget.product == null) {
        _future = _api.getDetail(widget.productId!);
      } else {
        _syncStockWithSelectedSize(widget.product!);
      }
    }

    void _syncStockWithSelectedSize(Product p) {
      if (_selectedSize == null) {
        _maxStock = 999;
        return;
      }
      final v = p.variants.where((e) => e.size == _selectedSize).toList();
      _maxStock = v.isEmpty ? 0 : v.first.stock;
      _qty = _qty.clamp(1, (_maxStock <= 0 ? 1 : _maxStock));
    }

    String _money(num v) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final idxFromEnd = s.length - i;
        buf.write(s[i]);
        if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
      }
      return '${buf.toString()}đ';
    }

    void _pickSize(Product p, String size, int stock) {
      setState(() {
        _selectedSize = size;
        _maxStock = stock;
        _qty = 1;
      });
    }

    void _decQty() {
      setState(() => _qty = (_qty - 1).clamp(1, 999));
    }

    void _incQty() {
      setState(() {
        final max = _maxStock <= 0 ? 1 : _maxStock;
        _qty = (_qty + 1).clamp(1, max);
      });
    }

    // --- PHẦN LOGIC ĐÃ SỬA ---
    void _addToCart(Product p) {
      if (_selectedSize == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn size trước')),
        );
        return;
      }
      _handleAddToCart(p, isBuyNow: false);
    }

    void _buyNow(Product p) {
      if (_selectedSize == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn size trước')),
        );
        return;
      }
      _handleAddToCart(p, isBuyNow: true);
    }

    Future<void> _handleAddToCart(Product p, {bool isBuyNow = false}) async {
    try {
      setState(() => _isAdding = true);

      await _cartRepo.addToCart(p.id, _qty, _selectedSize!);

      if (!mounted) return;

      setState(() => _isAdding = false);

      if (isBuyNow) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm ${p.name} vào giỏ hàng')),
        );
      }
    } catch (e) {
      setState(() => _isAdding = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }


    @override
    Widget build(BuildContext context) {
      // Case 1: đi từ GoRouter bằng productId -> load API
      if (widget.product == null) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7F8),
          appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
          body: FutureBuilder<Product>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Lỗi: ${snap.error}', textAlign: TextAlign.center));
              }
              final p = snap.data;
              if (p == null) return const Center(child: Text('Không tìm thấy sản phẩm'));

              // đồng bộ stock sau khi load (nếu user đã chọn size trước đó)
              _syncStockWithSelectedSize(p);

              return _DetailBody(
                product: p,
                money: _money,
                selectedImage: _selectedImage,
                onSelectImage: (i) => setState(() => _selectedImage = i),
                selectedSize: _selectedSize,
                qty: _qty,
                maxStock: _maxStock,
                onPickSize: (size, stock) => _pickSize(p, size, stock),
                onDec: _decQty,
                onInc: _incQty,
                onAddToCart: () => _addToCart(p),
                onBuyNow: () => _buyNow(p),
              );
            },
          ),
        );
      }

      // Case 2: đi từ List -> đã có product
      final p = widget.product!;
      _syncStockWithSelectedSize(p);

      return _DetailBody(
        product: p,
        money: _money,
        selectedImage: _selectedImage,
        onSelectImage: (i) => setState(() => _selectedImage = i),
        selectedSize: _selectedSize,
        qty: _qty,
        maxStock: _maxStock,
        onPickSize: (size, stock) => _pickSize(p, size, stock),
        onDec: _decQty,
        onInc: _incQty,
        onAddToCart: () => _addToCart(p),
        onBuyNow: () => _buyNow(p),
      );
    }
  }

  class _DetailBody extends StatelessWidget {
    final Product product;
    final String Function(num) money;
    final int selectedImage;
    final ValueChanged<int> onSelectImage;

    final String? selectedSize;
    final int qty;
    final int maxStock;

    final void Function(String size, int stock) onPickSize;
    final VoidCallback onDec;
    final VoidCallback onInc;

    final VoidCallback onAddToCart;
    final VoidCallback onBuyNow;

    const _DetailBody({
      required this.product,
      required this.money,
      required this.selectedImage,
      required this.onSelectImage,
      required this.selectedSize,
      required this.qty,
      required this.maxStock,
      required this.onPickSize,
      required this.onDec,
      required this.onInc,
      required this.onAddToCart,
      required this.onBuyNow,
    });

    @override
    Widget build(BuildContext context) {
      final p = product;

      final imgs = <String>{
        if (p.imageUrl.isNotEmpty) p.imageUrl,
        ...p.images.where((e) => e.isNotEmpty),
      }.toList();

      final mainUrl = imgs.isNotEmpty ? imgs[selectedImage.clamp(0, imgs.length - 1)] : '';

      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        appBar: AppBar(
          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 980;

            final left = _LeftGallery(
              mainUrl: mainUrl,
              images: imgs,
              selected: selectedImage,
              onSelect: onSelectImage,
            );

            final right = _RightInfo(
              product: p,
              money: money,
              selectedSize: selectedSize,
              qty: qty,
              maxStock: maxStock,
              onPickSize: onPickSize,
              onDec: onDec,
              onInc: onInc,
              onAddToCart: onAddToCart,
              onBuyNow: onBuyNow,
            );

            if (wide) {
              // Giao diện cho màn hình to (Web/Tablet)
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column( // Bọc Row vào trong Column để thêm Comment ở dưới
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: left),
                          const SizedBox(width: 18),
                          Expanded(flex: 5, child: right),
                        ],
                      ),
                      const SizedBox(height: 32), // Khoảng cách giữa thông tin SP và bình luận
                      // GỌI COMPONENT BÌNH LUẬN Ở ĐÂY 👇
                      ProductCommentSection(productId: p.id),
                    ],
                  ),
                ),
              );
            }
            

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    left,
                    const SizedBox(height: 14),
                    right,
                    const SizedBox(height: 32), // Khoảng cách giữa thông tin SP và bình luận
                    // GỌI COMPONENT BÌNH LUẬN Ở ĐÂY 👇
                   ProductCommentSection(productId: p.id), // Đã thêm chữ "Product" vào trước
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  class _LeftGallery extends StatelessWidget {
    final String mainUrl;
    final List<String> images;
    final int selected;
    final ValueChanged<int> onSelect;

    const _LeftGallery({
      required this.mainUrl,
      required this.images,
      required this.selected,
      required this.onSelect,
    });

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFFF3F3F3),
                  child: (mainUrl.isEmpty)
                      ? const Center(child: Icon(Icons.image_outlined, size: 48, color: Colors.black38))
                      : Image.network(
                          mainUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.black38),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (images.length > 1)
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final isSel = i == selected;
                    return InkWell(
                      onTap: () => onSelect(i),
                      child: Container(
                        width: 74,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? const Color(0xFFE11D48) : Colors.black12, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            images[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black12,
                              child: const Icon(Icons.image_not_supported_outlined),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }
  }

  class _RightInfo extends StatelessWidget {
    final Product product;
    final String Function(num) money;

    final String? selectedSize;
    final int qty;
    final int maxStock;

    final void Function(String size, int stock) onPickSize;
    final VoidCallback onDec;
    final VoidCallback onInc;
    final VoidCallback onAddToCart;
    final VoidCallback onBuyNow;

    const _RightInfo({
      required this.product,
      required this.money,
      required this.selectedSize,
      required this.qty,
      required this.maxStock,
      required this.onPickSize,
      required this.onDec,
      required this.onInc,
      required this.onAddToCart,
      required this.onBuyNow,
    });

    @override
    Widget build(BuildContext context) {
      final p = product;

      // Nếu variants rỗng => size sẽ không hiện -> bạn cần sửa Product.fromJson / backend
      final variants = p.variants.toList();
      variants.sort((a, b) => a.size.compareTo(b.size));

      final hasVariants = variants.isNotEmpty;
      final canAction = selectedSize != null && maxStock > 0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              'Thương hiệu: ${p.brand}',
              style: TextStyle(color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  money(p.hasDiscount ? p.finalPrice : p.price),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFFE11D48)),
                ),
                const SizedBox(width: 12),
                if (p.hasDiscount)
                  Text(
                    money(p.price),
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.35),
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),
            const Text('SIZE', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),

            if (!hasVariants)
              Text(
                'Không có dữ liệu size (variants đang rỗng). Kiểm tra Product.fromJson hoặc API.',
                style: TextStyle(color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w600),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: variants.map((v) {
                  final s = v.size;
                  final stock = v.stock;
                  final sel = s == selectedSize;
                  final out = stock <= 0;

                  return InkWell(
                    onTap: out ? null : () => onPickSize(s, stock),
                    child: Opacity(
                      opacity: out ? 0.45 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? const Color(0xFFE11D48) : Colors.black12, width: 2),
                          color: sel ? const Color(0xFFFFEEF1) : Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: sel ? const Color(0xFFE11D48) : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: out ? Colors.black12 : Colors.black.withOpacity(0.06),
                              ),
                              child: Text(
                                out ? 'Hết' : 'Còn $stock',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.65),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Số lượng', style: TextStyle(fontWeight: FontWeight.w900)),
                const Spacer(),
                if (selectedSize != null)
                  Text(
                    maxStock <= 0 ? 'Hết hàng' : 'Tồn: $maxStock',
                    style: TextStyle(color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _QtyBtn(icon: Icons.remove, onTap: onDec),
                Container(
                  width: 54,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                _QtyBtn(icon: Icons.add, onTap: onInc),
              ],
            ),

            const SizedBox(height: 16),

            // 2 nút: Thêm giỏ + Mua ngay
          Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    // Đã sửa thành _selectedSize cho khớp với khai báo của bạn
                  onPressed: canAction ? onAddToCart : null,
  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Giỏ hàng', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                  onPressed: selectedSize == null ? null : onBuyNow,
  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Mua ngay', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),

            if (selectedSize == null) ...[
              const SizedBox(height: 10),
              Text(
                'Hãy chọn size để thao tác mua/thêm giỏ.',
                style: TextStyle(color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w700),
              ),
            ],

            const SizedBox(height: 18),
            const Divider(height: 24),
            const Text('Thông tin sản phẩm', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              p.description.isEmpty ? 'Chưa có mô tả.' : p.description,
              style: TextStyle(color: Colors.black.withOpacity(0.75), height: 1.35),
            ),
          ],
        ),
      );
    }
  }

  class _QtyBtn extends StatelessWidget {
    final IconData icon;
    final VoidCallback onTap;
    const _QtyBtn({required this.icon, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: 44,
        height: 44,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: Colors.black12),
          ),
          onPressed: onTap,
          child: Icon(icon),
        ),
      );
    }
  }
  // Đảm bảo bạn đã import thư viện này ở đầu file
  