import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; 
import '../../../core/api/dio_client.dart'; // Sử dụng DioClient thay vì tạo Dio mới
import '../domain/comment_model.dart';

class CommentApi {
  // 🚩 SỬA: Dùng trực tiếp instance dio từ DioClient để thừa hưởng baseUrl và Interceptors (Token)
  final Dio dio = DioClient.dio;

  // Lấy danh sách comment (Public)
  Future<List<Comment>> getComments(String productId) async {
    try {
      // 🚩 SỬA: Bỏ '/api/v1' vì trong DioClient đã có rồi
      final res = await dio.get('/comments/product/$productId');
      
      final data = res.data['data'] as List;
      return data.map((e) => Comment.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ✅ HÀM UPLOAD ẢNH
  Future<List<String>> uploadImages(List<XFile> images, String token) async {
    try {
      FormData formData = FormData();
      
      for (XFile file in images) {
        final bytes = await file.readAsBytes();
        
        formData.files.add(MapEntry(
          "images", 
          MultipartFile.fromBytes(
            bytes,
            filename: file.name,
          ),
        ));
      }

      // 🚩 SỬA: Bỏ '/api/v1'
      final res = await dio.post(
        '/comments/upload', 
        data: formData,
        // Không cần truyền header thủ công vì DioClient.dio đã tự động lấy token từ SecureStore
      );
      
      if (res.data['ok'] == true) {
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

  // Thêm bình luận
  Future<void> postComment(String productId, String content, List<String> images, String token) async {
    try {
      // 🚩 SỬA: Bỏ '/api/v1'
      await dio.post(
        '/comments/product/$productId', 
        data: {
          'content': content,
          'images': images, 
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Vui lòng đăng nhập để bình luận');
      }
      throw Exception('Lỗi khi gửi bình luận: ${e.response?.data['message'] ?? e.message}');
    }
  }
}