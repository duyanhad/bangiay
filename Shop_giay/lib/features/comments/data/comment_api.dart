import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; 

import '../../../core/config/app_config.dart';
import '../domain/comment_model.dart';

class CommentApi {
  final Dio dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  // Lấy danh sách comment (Public)
  Future<List<Comment>> getComments(String productId) async {
    try {
      final res = await dio.get('/api/v1/comments/product/$productId');
      
      final data = res.data['data'] as List;
      return data.map((e) => Comment.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tải bình luận: $e');
    }
  }

  // ✅ HÀM UPLOAD ẢNH: Đã sửa lỗi 404 và hỗ trợ Web/Mobile
  Future<List<String>> uploadImages(List<XFile> images, String token) async {
    
    try {
      FormData formData = FormData();
      
      for (XFile file in images) {
        final bytes = await file.readAsBytes();
        
        // Sử dụng MapEntry để thêm nhiều file cùng key "images" như Server yêu cầu
        formData.files.add(MapEntry(
          "images", 
          MultipartFile.fromBytes(
            bytes,
            filename: file.name,
          ),
        ));
      }

      final res = await dio.post(
        '/api/v1/comments/upload', // 🚩 ĐÃ SỬA: Phải là /api/v1/comments/upload mới đúng route index.js và comment.route.js
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'}, // Thêm token vì route này yêu cầu requireAuth
        ),
      );
      
      if (res.data['ok'] == true) {
        // Backend trả về mảng ["/uploads/file.jpg", ...]
        return List<String>.from(res.data['data']);
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print("Chi tiết lỗi Server: ${e.response?.data}");
      }
      throw Exception('Lỗi khi upload ảnh: $e');
    }
  }

  // Thêm bình luận (Gửi kèm mảng images)
  Future<void> postComment(String productId, String content, List<String> images, String token) async {
    try {
      await dio.post(
        '/api/v1/comments/product/$productId', 
        data: {
          'content': content,
          'images': images, // Gửi danh sách đường dẫn ảnh đã upload thành công
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Vui lòng đăng nhập để bình luận');
      }
      throw Exception('Lỗi khi gửi bình luận: ${e.response?.data['message'] ?? e.message}');
    }
  }
}