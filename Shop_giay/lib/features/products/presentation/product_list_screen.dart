import 'package:flutter/material.dart';
import '../../../core/config/banner_config.dart';
import '../data/product_api.dart';
import '../domain/product_model.dart';
import 'product_detail_screen.dart';
import 'widgets/product_card.dart';

enum _FilterType { all, category, sale }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final ProductApi _api;
  late Future<List<Product>> _future;

  _FilterType _filterType = _FilterType.all;
  String? _selectedCategory;

  // (optional) text search applied to grid (không bắt buộc vì search delegate đã có)
  String _search = '';

  @override
  void initState() {
    super.initState();
    _api = ProductApi();
    _future = _api.fetchProducts(page: 1, limit: 60);
  }

  int _crossAxisCount(double w) {
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    return 2;
  }

  List<Product> _applyFilter(List<Product> items) {
    var out = items;

    if (_filterType == _FilterType.sale) {
      out = out.where((p) => p.hasDiscount).toList();
    } else if (_filterType == _FilterType.category && _selectedCategory != null) {
      final key = _selectedCategory!.toLowerCase();
      out = out.where((p) => p.category.toLowerCase() == key).toList();
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    }

    return out;
  }

  void _selectAll() {
    setState(() {
      _filterType = _FilterType.all;
      _selectedCategory = null;
      _search = '';
    });
    Navigator.pop(context);
  }

  void _selectSale() {
    setState(() {
      _filterType = _FilterType.sale;
      _selectedCategory = null;
      _search = '';
    });
    Navigator.pop(context);
  }

  void _selectCategory(String cat) {
    setState(() {
      _filterType = _FilterType.category;
      _selectedCategory = cat;
      _search = '';
    });
    Navigator.pop(context);
  }

  Future<void> _openLiveSearch() async {
    final list = await _future;

    if (!mounted) return;

    final picked = await showSearch<Product?>(
      context: context,
      delegate: _ProductSearchDelegate(list),
    );

    if (picked != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: picked)),
      );
    }
  }

  void _refreshAll() {
    setState(() {
      _filterType = _FilterType.all;
      _selectedCategory = null;
      _search = '';
      _future = _api.fetchProducts(page: 1, limit: 60);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Drawer filter
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            children: [
              const Text('NEW ARRIVAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 14),

              _DrawerItem(
                title: 'ALL PRODUCTS',
                subtitle: 'Xem tất cả',
                onTap: _selectAll,
              ),
              _DrawerItem(
                title: 'SALE OFF',
                subtitle: 'Sản phẩm đang giảm giá',
                onTap: _selectSale,
              ),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              const Text('CATEGORIES', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),

              _DrawerItem(title: 'Nike', onTap: () => _selectCategory('Nike')),
              _DrawerItem(title: 'Adidas', onTap: () => _selectCategory('Adidas')),
              _DrawerItem(title: 'Running', onTap: () => _selectCategory('Running')),
              _DrawerItem(title: 'Sneaker', onTap: () => _selectCategory('Sneaker')),
              _DrawerItem(title: 'Casual', onTap: () => _selectCategory('Casual')),
              _DrawerItem(title: 'Skateboarding', onTap: () => _selectCategory('Skateboarding')),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              _DrawerItem(
                title: 'SIZE CHART',
                subtitle: 'Bảng size (demo)',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Size Chart'),
                      content: Text('Bạn có thể làm trang này sau.'),
                    ),
                  );
                },
              ),
              _DrawerItem(
                title: 'ABOUT US',
                subtitle: 'Thông tin cửa hàng (demo)',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('About Us'),
                      content: Text('Bạn có thể làm trang này sau.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      backgroundColor: const Color(0xFFF6F7F8),

      body: SafeArea(
        child: FutureBuilder<List<Product>>(
          future: _future,
          builder: (context, snap) {
            final w = MediaQuery.of(context).size.width;

            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Text('Lỗi: ${snap.error}', textAlign: TextAlign.center),
              );
            }

            final all = snap.data ?? [];
            final items = _applyFilter(all);

            final filterText = switch (_filterType) {
              _FilterType.all => 'Tất cả sản phẩm',
              _FilterType.sale => 'Giảm giá',
              _FilterType.category => 'Danh mục: ${_selectedCategory ?? ''}',
            };

            return CustomScrollView(
              slivers: [
                // TOP BAR
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: const Center(
                      child: Text(
                        'Đăng ký   /   Đăng nhập',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),

                // HEADER
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 1,
                  toolbarHeight: 64,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  title: const Text('Shop Giày', style: TextStyle(fontWeight: FontWeight.w900)),
                  actions: [
                    IconButton(
                      tooltip: 'Reset + Reload',
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshAll,
                    ),
                    IconButton(
                      tooltip: 'Search',
                      icon: const Icon(Icons.search),
                      onPressed: _openLiveSearch,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // ✅ BANNER (assets/network)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: const _PromoBanner(),
                  ),
                ),

                // FILTER TITLE
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            filterText,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${items.length} sản phẩm', style: TextStyle(color: Colors.black.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ),

                // BEST SELLER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text('BEST SELLER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        ),
                        Expanded(child: Divider(color: Colors.black.withOpacity(0.15), thickness: 1)),
                      ],
                    ),
                  ),
                ),

                // GRID
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = items[index];
                        return ProductCard(
                          product: p,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                            );
                          },
                        );
                      },
                      childCount: items.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _crossAxisCount(w),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: Colors.black.withOpacity(0.6))),
      trailing: const Icon(Icons.add),
      onTap: onTap,
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final list = BannerConfig.items.isEmpty
        ? const ['asset:banners/banner1.jpg']
        : BannerConfig.items;

    Widget buildImage(String src) {
      // ✅ asset:... => Image.asset('assets/...')
      if (src.startsWith('asset:')) {
        final p = src.substring('asset:'.length); // banners/banner1.jpg
        return Image.asset(
          'assets/$p', // ✅ chỉ thêm 1 lần assets/
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.black12,
            child: const Center(child: Icon(Icons.image_not_supported_outlined)),
          ),
        );
      }

      // network url
      return Image.network(
        src,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.black12,
          child: const Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 6,
        child: PageView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => buildImage(list[i]),
        ),
      ),
    );
  }
}

class _ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> all;

  _ProductSearchDelegate(this.all);

  @override
  String? get searchFieldLabel => 'Tìm tên / brand / category...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  List<Product> _filter() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all.take(20).toList();

    final res = all.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return res.take(30).toList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final items = _filter();

    if (items.isEmpty) {
      return const Center(child: Text('Không tìm thấy sản phẩm'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = items[i];
        return ListTile(
          leading: SizedBox(
            width: 52,
            height: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: p.displayImage.isEmpty
                  ? Container(color: Colors.black12, child: const Icon(Icons.image_outlined))
                  : Image.network(
                      p.displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.black12, child: const Icon(Icons.image_outlined)),
                    ),
            ),
          ),
          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${p.brand} • ${p.category}', maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => close(context, p), // ✅ click -> mở detail ở caller
        );
      },
    );
  }
}
