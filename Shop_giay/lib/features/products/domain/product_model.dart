class ProductVariant {
  final String size; // "38","39"...
  final int stock;

  const ProductVariant({required this.size, required this.stock});
}

String _sanitizeUrl(String input) {
  var s = input.trim();

  if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
    s = s.substring(1, s.length - 1).trim();
  }

  while (s.endsWith(',') || s.endsWith("'") || s.endsWith('"')) {
    s = s.substring(0, s.length - 1).trim();
  }
  return s;
}

num _parseNum(dynamic v) {
  if (v is num) return v;
  return num.tryParse((v ?? '0').toString()) ?? 0;
}

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '0').toString()) ?? 0;
}

bool _parseBool(dynamic v, {bool fallback = true}) {
  if (v is bool) return v;
  final s = (v ?? '').toString().toLowerCase().trim();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

String _parseMongoId(dynamic raw) {
  // raw có thể là {"$oid": "..."} hoặc string
  if (raw is Map) {
    // Dùng r'$oid' để tránh mọi vấn đề với ký tự '$'
    final dynamic v = raw[r'$oid'];
    if (v != null) return v.toString();
    return '';
  }
  return raw == null ? '' : raw.toString();
}


class Product {
  // IDs
  final String id; // mongo _id (string)
  final int? numericId; // field "id": 1,2,3...

  // Basic
  final String name;
  final String brand;
  final String category;

  // Pricing
  final num price;
  final num finalPrice;
  final int discount;

  // Inventory
  final int stock; // tổng stock
  final List<ProductVariant> variants; // size + stock theo size

  // Extra info
  final List<String> colors;
  final String material;
  final String description;
  final bool isActive;

  // Images
  final List<String> images;
  final String imageUrl;

  const Product({
    required this.id,
    required this.numericId,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.finalPrice,
    required this.discount,
    required this.stock,
    required this.variants,
    required this.colors,
    required this.material,
    required this.description,
    required this.isActive,
    required this.images,
    required this.imageUrl,
    
  });

  bool get hasDiscount => discount > 0 && finalPrice > 0 && finalPrice < price;

  String get displayImage {
    if (imageUrl.isNotEmpty) return imageUrl;
    if (images.isNotEmpty) return images.first;
    return '';
  }

  int stockOfSize(String size) {
    final v = variants.where((e) => e.size == size).toList();
    return v.isEmpty ? 0 : v.first.stock;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // ✅ parse mongo _id đúng
    final mongoId = _parseMongoId(json['_id']);

    // numeric id
    final numericIdRaw = json['id'];
    final int? numericId = (numericIdRaw is num)
        ? numericIdRaw.toInt()
        : int.tryParse((numericIdRaw ?? '').toString());

    // ✅ Images list (chịu được List/String/null)
    final imagesRaw = json['images'] ?? json['imageUrls'] ?? json['image'];
    final List<String> images = (imagesRaw is List)
        ? imagesRaw
            .map((e) => _sanitizeUrl(e.toString()))
            .where((u) => u.isNotEmpty)
            .toList()
        : (imagesRaw is String && imagesRaw.trim().isNotEmpty
            ? [_sanitizeUrl(imagesRaw)]
            : <String>[]);

    // image_url string
    final imageUrl = _sanitizeUrl((json['image_url'] ?? json['imageUrl'] ?? '').toString());

    // Colors
    final colorsRaw = json['colors'];
    final List<String> colors = (colorsRaw is List)
        ? colorsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    // sizes list
    final sizesRaw = json['sizes'];
    final List<String> sizes = (sizesRaw is List)
        ? sizesRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    // size_stocks map
    final Map<String, dynamic> sizeStocksRaw =
        (json['size_stocks'] is Map) ? Map<String, dynamic>.from(json['size_stocks']) : <String, dynamic>{};

    // Build variants
    List<ProductVariant> variants = [];
    if (sizes.isNotEmpty) {
      variants = sizes.map((s) {
        final st = sizeStocksRaw[s];
        return ProductVariant(size: s, stock: _parseInt(st));
      }).toList();
    } else if (sizeStocksRaw.isNotEmpty) {
      variants = sizeStocksRaw.entries
          .map((e) => ProductVariant(size: e.key.toString(), stock: _parseInt(e.value)))
          .where((v) => v.size.isNotEmpty)
          .toList()
        ..sort((a, b) => a.size.compareTo(b.size));
    } else {
      // fallback legacy: variants array
      final variantsRaw = json['variants'];
      if (variantsRaw is List) {
        variants = variantsRaw
            .map((e) {
              if (e is Map<String, dynamic>) {
                final size = (e['size'] ?? e['label'] ?? '').toString().trim();
                final stock = _parseInt(e['stock'] ?? e['quantity']);
                return ProductVariant(size: size, stock: stock);
              }
              if (e is String) {
                return ProductVariant(size: e.trim(), stock: 0);
              }
              return const ProductVariant(size: '', stock: 0);
            })
            .where((v) => v.size.isNotEmpty)
            .toList();
      }
    }

    final priceRaw = json['price'] ?? 0;
    final finalPriceRaw = json['final_price'] ?? json['finalPrice'] ?? priceRaw;
    final discountRaw = json['discount'] ?? 0;

    final resolvedId = mongoId.isNotEmpty ? mongoId : (numericId?.toString() ?? '');

    return Product(
      id: resolvedId,
      numericId: numericId,
      name: (json['name'] ?? json['title'] ?? '').toString(),
      brand: (json['brand'] ?? json['vendor'] ?? 'Sneaker').toString(),
      category: (json['category'] ?? '').toString(),
      price: _parseNum(priceRaw),
      finalPrice: _parseNum(finalPriceRaw),
      discount: _parseInt(discountRaw),
      stock: _parseInt(json['stock']),
      variants: variants,
      colors: colors,
      material: (json['material'] ?? '').toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      isActive: _parseBool(json['isActive'], fallback: true),
      images: images,
      imageUrl: imageUrl,
    );
  }
}
