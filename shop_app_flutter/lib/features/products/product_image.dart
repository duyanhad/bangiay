import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ảnh sản phẩm (hỗ trợ link ngoài).
/// - Có loading + errorBuilder (không bị icon vỡ trống)
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final child = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      // Loading
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      // Fallback khi lỗi (web hay bị chặn hotlink)
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_not_supported),
              if (kDebugMode) ...[
                const SizedBox(height: 6),
                const Text("Image load failed", style: TextStyle(fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );

    if (borderRadius == null) return child;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }
}
