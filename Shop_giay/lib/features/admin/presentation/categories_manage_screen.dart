import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/admin_colors.dart';
import '../presentation/admin_controller.dart';
import '../widgets/admin_drawer.dart';

class CategoriesManageScreen extends StatefulWidget {
  const CategoriesManageScreen({super.key});

  @override
  State<CategoriesManageScreen> createState() =>
      _CategoriesManageScreenState();
}

class _CategoriesManageScreenState
    extends State<CategoriesManageScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<AdminController>().loadCategories());
  }

  void _showCategoryDialog({Map? category}) {
    final nameCtrl =
        TextEditingController(text: category?['name'] ?? '');
    final descCtrl =
        TextEditingController(text: category?['description'] ?? '');

    final isEdit = category != null;
    final id = category?['_id'] ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit
            ? "Chỉnh sửa danh mục"
            : "Thêm danh mục"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: "Tên danh mục"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: "Mô tả"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final controller =
                  context.read<AdminController>();

              final data = {
                "name": nameCtrl.text.trim(),
                "description": descCtrl.text.trim(),
              };

              bool success;

              if (isEdit) {
                success = await controller
                    .updateCategory(id, data);
              } else {
                success = await controller
                    .createCategory(data);
              }

              if (!mounted) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(success
                      ? "Thành công"
                      : "Thất bại"),
                  backgroundColor:
                      success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text(isEdit ? "Cập nhật" : "Thêm"),
          )
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa danh mục?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<AdminController>()
                  .deleteCategory(id);
            },
            child: const Text("Xóa",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<AdminController>();

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text("Quản lý danh mục"),
        backgroundColor: AdminColors.header1,
        foregroundColor: Colors.white,
      ),
      floatingActionButton:
          FloatingActionButton(
        backgroundColor: AdminColors.header1,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: controller.isLoadingCategories
          ? const Center(
              child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  controller.categories.length,
              itemBuilder: (_, i) {
                final c =
                    controller.categories[i];
                final id = c['_id'];

                return Card(
                  child: ListTile(
                    title: Text(
                      c['name'] ?? '',
                      style: const TextStyle(
                          fontWeight:
                              FontWeight.bold),
                    ),
                    subtitle:
                        Text(c['description'] ?? ''),
                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.edit,
                              color: Colors.blue),
                          onPressed: () =>
                              _showCategoryDialog(
                                  category: c),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete,
                              color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}