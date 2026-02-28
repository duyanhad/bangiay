import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/admin_colors.dart';
import '../widgets/admin_drawer.dart';
import '../presentation/admin_controller.dart';
import 'package:shop_giay/core/api/dio_client.dart';

class CommentsManageScreen extends StatefulWidget {
  const CommentsManageScreen({super.key});

  @override
  State<CommentsManageScreen> createState() => _CommentsManageScreenState();
}

class _CommentsManageScreenState extends State<CommentsManageScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().loadAdminComments();
    });
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return "${DioClient.hostUrl}$path";
  }

  String _getUserName(dynamic c) {
    try {
      if (c['userName'] != null) {
        return c['userName'].toString();
      }

      if (c['userId'] is Map && c['userId']['name'] != null) {
        return c['userId']['name'].toString();
      }
    } catch (_) {}

    return "Người dùng ẩn danh";
  }

  String _getProductName(dynamic c) {
    try {
      if (c['productId'] is Map && c['productId']['name'] != null) {
        return c['productId']['name'].toString();
      }
    } catch (_) {}

    return "Sản phẩm đã xóa";
  }

  List _getImages(dynamic c) {
    if (c['images'] is List) {
      return c['images'];
    }
    return [];
  }

  bool _isReplied(dynamic c) {
    if (c['reply'] != null && c['reply'].toString().isNotEmpty) {
      return true;
    }

    if (c['replies'] is List && (c['replies'] as List).isNotEmpty) {
      return true;
    }

    return false;
  }

  String _getReplyContent(dynamic c) {
    if (c['reply'] != null) return c['reply'].toString();

    if (c['replies'] is List && (c['replies'] as List).isNotEmpty) {
      final r = (c['replies'] as List).first;
      if (r is Map && r['content'] != null) {
        return r['content'].toString();
      }
    }

    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text(
          "Quản lý Bình luận",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AdminColors.header,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                context.read<AdminController>().loadAdminComments(),
          )
        ],
      ),
      body: Consumer<AdminController>(
        builder: (context, controller, child) {

          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final comments = controller.adminComments;

          if (comments.isEmpty) {
            return const Center(child: Text("Chưa có bình luận nào."));
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadAdminComments(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: comments.length,
              itemBuilder: (context, index) {

                final c = comments[index];

                final String cId =
                    (c['_id'] ?? c['id'] ?? "").toString();

                final String userName = _getUserName(c);
                final String productName = _getProductName(c);

                final images = _getImages(c);

                final bool isReplied = _isReplied(c);

                final bool isHidden = c['isHidden'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isHidden ? Colors.grey[100] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHidden
                          ? Colors.grey.shade400
                          : (isReplied
                              ? Colors.green.shade200
                              : Colors.orange.shade200),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Opacity(
                    opacity: isHidden ? 0.6 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AdminColors.header.withOpacity(0.1),
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : "?",
                            ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            c['createdAt'] != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(
                                    DateTime.parse(c['createdAt']))
                                : "Không rõ ngày",
                          ),
                          trailing:
                              _buildStatusTag(isReplied, isHidden),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < (c['rating'] ?? 5)
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                c['content'] ?? "",
                                style: const TextStyle(fontSize: 15),
                              ),

                              if (images.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10),
                                  child: Wrap(
                                    spacing: 8,
                                    children: images.map((img) {
                                      return ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          _getFullImageUrl(img),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                                Icons.broken_image),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              const SizedBox(height: 10),

                              Text(
                                "Sản phẩm: $productName",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isReplied)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getReplyContent(c),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),

                        const Divider(height: 1),

                        ButtonBar(
                          children: [

                            TextButton.icon(
                              onPressed: isHidden
                                  ? null
                                  : () =>
                                      _showReplyDialog(context, cId),
                              icon: const Icon(Icons.reply),
                              label: Text(
                                  isReplied ? "Sửa" : "Trả lời"),
                            ),

                            TextButton.icon(
                              onPressed: () =>
                                  controller.handleHide(
                                      cId, !isHidden),
                              icon: Icon(
                                isHidden
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.orange,
                              ),
                              label: Text(
                                isHidden ? "Hiện" : "Ẩn",
                                style: const TextStyle(
                                    color: Colors.orange),
                              ),
                            ),

                            TextButton.icon(
                              onPressed: () =>
                                  _confirmDelete(context, cId),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              label: const Text(
                                "Xóa",
                                style:
                                    TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTag(bool isReplied, bool isHidden) {
    String text = isHidden ? "Đã ẩn" : (isReplied ? "Đã trả lời" : "Chờ");
    Color color =
        isHidden ? Colors.grey : (isReplied ? Colors.green : Colors.orange);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String commentId) {

    final textController = TextEditingController();
    final adminCtrl = context.read<AdminController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Phản hồi"),
        content: TextField(
          controller: textController,
          decoration:
              const InputDecoration(hintText: "Nhập nội dung..."),
        ),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),

          ElevatedButton(
            onPressed: () async {

              final content = textController.text.trim();

              if (content.isEmpty) return;

              await adminCtrl.handleReply(commentId, content);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xác nhận xóa?"),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {

              await context.read<AdminController>().deleteComment(id);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
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
}