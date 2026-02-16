import 'package:flutter/material.dart';
import '../data/admin_api.dart';
import '../data/admin_models.dart';

class AdminController extends ChangeNotifier {
  final AdminApi _api = AdminApi();

  AdminStats? stats;
  bool isLoading = false;
  String? error;

  Future<void> loadStats() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      stats = await _api.getStats();
    } catch (e) {
      error = e.toString();
      stats = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}