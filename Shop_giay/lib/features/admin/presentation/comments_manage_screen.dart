import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/admin_colors.dart';
import '../widgets/admin_drawer.dart';

class CommentsManageScreen extends StatefulWidget {
  const CommentsManageScreen({super.key});

  @override
  State<CommentsManageScreen> createState() => _CommentsManageScreenState();
}

class _CommentsManageScreenState extends State<CommentsManageScreen> {
  // Dữ liệu giả
  final List<Map<String, dynamic>> _comments = [
    {
      "id": 1,
      "user": "Nguyễn Văn A",
      "product": "iPhone 15 Pro Max",
      "content": "Sản phẩm rất đẹp, giao hàng nhanh!",
      "rating": 5,
      "date": DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      "id": 2,
      "user": "Trần Thị B",
      "product": "Tai nghe Sony",
      "content": "Nghe hơi bé, không đáng tiền.",
      "rating": 3,
      "date": DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text("Quản lý Bình luận"),
        backgroundColor: AdminColors.header1,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _comments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = _comments[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('dd/MM HH:mm').format(c['date']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: List.generate(5, (i) => Icon(i < c['rating'] ? Icons.star : Icons.star_border, size: 16, color: Colors.amber))),
                const SizedBox(height: 8),
                Text(c['content']),
                const SizedBox(height: 8),
                Text("SP: ${c['product']}", style: TextStyle(fontSize: 12, color: Colors.blue[800], fontStyle: FontStyle.italic)),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    label: const Text("Xóa", style: TextStyle(color: Colors.red)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}