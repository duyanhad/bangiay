import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

import '../features/auth/auth_service.dart';
import '../features/products/product_service.dart';
import '../features/products/product_provider.dart';
import '../features/cart/cart_provider.dart';
import '../features/orders/order_service.dart';

List<SingleChildWidget> buildProviders() {
  final storage = TokenStorage();
  final api = ApiClient(storage);

  return [
    // ✅ Core (PHẢI Ở TRÊN CÙNG)
    Provider<TokenStorage>.value(value: storage),
    Provider<ApiClient>.value(value: api),

    // ✅ Services (phụ thuộc ApiClient)
    Provider<AuthService>(create: (_) => AuthService(api, storage)),
    Provider<ProductService>(create: (_) => ProductService(api)),
    Provider<OrderService>(create: (_) => OrderService(api.dio)),


    // ✅ State
    ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
    ChangeNotifierProvider<ProductProvider>(
      create: (context) => ProductProvider(context.read<ProductService>()),
    ),
  ];
}
