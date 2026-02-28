import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; // Bổ sung để upload ảnh
import 'package:http_parser/http_parser.dart'; // Bổ sung để format ảnh

import '../../../core/api/dio_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/product_model.dart';
import '../../comments/domain/comment_model.dart'; // Bổ sung model Comment của bạn

class ProductApi {
  // ---------------------------------------------------------------------------
  // PHẦN API SẢN PHẨM CŨ (Giữ nguyên)
  // ---------------------------------------------------------------------------
  
  /// Used by ProductListScreen which expects pagination params.
  Future<List<Product>> fetchProducts({int page = 1, int limit = 60}) async {
    final Response res = await DioClient.dio.get(
      Endpoints.products,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = res.data;
    final List items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Product>> getProducts() async {
    return fetchProducts(page: 1, limit: 60);
  }

  Future<Product> getDetail(String id) async {
    final Response res = await DioClient.dio.get('${Endpoints.products}/$id');
    final data = res.data;

    if (data is Map && data['data'] is Map) {
      return Product.fromJson(Map<String, dynamic>.from(data['data']));
    }
    if (data is Map) {
      return Product.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid product detail response');
  }

  // ---------------------------------------------------------------------------
  // PHẦN API COMMENT MỚI ĐƯỢC GỘP VÀO
  // ---------------------------------------------------------------------------

  // 1. Lấy danh sách comment của sản phẩm
  Future<List<Comment>> getComments(String productId) async {
    try {
      final res = await DioClient.dio.get('/comments/product/$productId');
      final data = res.data['data'] as List;
      return data.map((e) => Comment.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải bình luận: $e');
    }
  }

  // 2. Upload ảnh (Hỗ trợ Web và Mobile)
  Future<List<String>> uploadImages(List<XFile> images) async { 
    try {
      FormData formData = FormData();
      
      for (XFile file in images) {
        final bytes = await file.readAsBytes();
        final String fileExtension = file.name.split('.').last.toLowerCase();
        final String mimeType = (fileExtension == 'png') ? 'png' : 'jpeg';

        formData.files.add(MapEntry(
          "images", 
          MultipartFile.fromBytes(
            bytes,
            filename: file.name,
            contentType: MediaType("image", mimeType),
          ),
        ));
      }

      final res = await DioClient.dio.post(
        '/comments/upload',
        data: formData,
      );
      
      if (res.data['ok'] == true) {
        return List<String>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi khi upload ảnh: $e');
    }
  }

  // 3. Đăng bình luận
  Future<void> postComment(String productId, String content, List<String> images, {int rating = 5}) async {
    try {
      await DioClient.dio.post(
        '/comments/product/$productId', 
        data: {
          'content': content,
          'rating': rating,
          'images': images, 
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Vui lòng đăng nhập để bình luận');
      }
      throw Exception('Lỗi khi gửi bình luận: ${e.response?.data?['message'] ?? e.message}');
    }
  }
}