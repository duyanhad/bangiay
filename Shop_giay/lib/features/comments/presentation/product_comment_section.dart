import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// SỬA THÀNH ĐƯỜNG DẪN TƯƠNG ĐỐI (Dấu chấm)
import '../data/comment_api.dart';
import '../domain/comment_model.dart';
import '../../../core/api/dio_client.dart'; 
import '../../../core/storage/secure_store.dart';

class ProductCommentSection extends StatefulWidget {
  final String productId;

  const ProductCommentSection({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductCommentSection> createState() => _ProductCommentSectionState();
}

class _ProductCommentSectionState extends State<ProductCommentSection> {
  final CommentApi _commentApi = CommentApi();
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Comment> _comments = [];
  List<XFile> _selectedImages = [];
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- LOGIC: TẢI BÌNH LUẬN ---
  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _commentApi.getComments(widget.productId);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      debugPrint('Lỗi tải bình luận: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: CHỌN ẢNH TỪ THƯ VIỆN ---
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được chọn tối đa 5 ảnh')),
      );
      return;
    }

    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedImages);
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.sublist(0, 5);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã giới hạn lại 5 ảnh')),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // --- LOGIC: GỬI BÌNH LUẬN ---
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung hoặc chọn ảnh!')),
      );
      return;
    }

    // Lấy Token thật của user
    String? userToken = await SecureStore.getToken(); 

    if (userToken == null || userToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> uploadedImageUrls = [];
      
      // 1. Upload mảng ảnh lên Server
      if (_selectedImages.isNotEmpty) {
        uploadedImageUrls = await _commentApi.uploadImages(_selectedImages, userToken);
      }

      // 2. Gửi Text + Mảng Link ảnh
      await _commentApi.postComment(
        widget.productId,
        _commentController.text.trim(),
        uploadedImageUrls,
        userToken,
      );

      // 3. Thành công -> Reset form
      _commentController.clear();
      setState(() => _selectedImages.clear());
      FocusScope.of(context).unfocus();
      await _fetchComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi đánh giá thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getFullImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${DioClient.hostUrl}$path';
  }

  // =========================================================
  // ===================== GIAO DIỆN (UI) ====================
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 4, color: Colors.black12),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Đánh giá & Bình luận', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        
        _buildCommentForm(),

        const SizedBox(height: 16),

        _isLoading
            ? const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ))
            : _comments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text("Chưa có bình luận nào. Hãy là người đầu tiên!", style: TextStyle(color: Colors.grey))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) => _buildCommentItem(_comments[index]),
                  ),
      ],
    );
  }

  // UI: FORM NHẬP BÌNH LUẬN
  Widget _buildCommentForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập đánh giá của bạn về sản phẩm...',
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8, top: 8),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          image: DecorationImage(
                            image: kIsWeb 
                                ? NetworkImage(_selectedImages[index].path) as ImageProvider
                                : FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _removeSelectedImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text('Thêm ảnh (${_selectedImages.length}/5)'),
                style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Gửi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // UI: ITEM BÌNH LUẬN + PHẢN HỒI TỪ SHOP
  Widget _buildCommentItem(Comment c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.userName ?? "Người dùng", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Text(c.content ?? "", style: const TextStyle(fontSize: 14, height: 1.4)),
          
          if (c.images != null && c.images!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.images!.map((imgPath) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _getFullImageUrl(imgPath),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                );
              }).toList(),
            ),
          ],

          // GIAO DIỆN PHẢN HỒI TỪ SHOP
          if (c.replies != null && c.replies!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: c.replies!.map((reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.storefront_rounded, size: 16, color: Colors.blueAccent),
                          SizedBox(width: 6),
                          Text('Phản hồi từ Shop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(reply.content ?? "", style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.8), height: 1.4)),
                    ],
                  ),
                )).toList(),
              ),
            )
        ],
      ),
    );
  }
}