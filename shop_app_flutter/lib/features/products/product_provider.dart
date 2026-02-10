import 'package:flutter/material.dart';
import 'product_model.dart';
import 'product_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._service);
  final ProductService _service;

  List<String> brands = [];
  List<Product> products = [];
  String? selectedBrand;
  bool loading = false;

  Future<void> loadBrands() async {
    try {
      brands = await _service.fetchBrands();
    } catch (_) {
      brands = [];
    }
    notifyListeners();
  }

  Future<void> loadProducts({String? brand}) async {
    loading = true;
    notifyListeners();

    try {
      selectedBrand = brand;
      products = await _service.fetchProducts(brand: brand);
    } catch (_) {
      products = [];
    }

    loading = false;
    notifyListeners();
  }
}
