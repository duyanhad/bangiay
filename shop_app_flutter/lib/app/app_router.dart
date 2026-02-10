import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/products/home_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/cart/checkout_screen.dart';
import '../features/cart/thank_you_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: "/login",
    routes: [
      GoRoute(path: "/login", builder: (_, __) => const LoginScreen()),
      GoRoute(
  path: "/home",
  builder: (_, __) => const HomeScreen(),
),
GoRoute(
  path: "/product/:id",
  builder: (context, state) =>
      ProductDetailScreen(productId: state.pathParameters['id']!),
),

GoRoute(
  path: "/cart",
  builder: (_, __) => const CartScreen(),
),
      // Các route khác bạn sẽ thêm dần ở bước sau
      GoRoute(
  path: "/checkout",
  builder: (_, __) => const CheckoutScreen(),
),
GoRoute(
  path: "/thankyou",
  builder: (_, __) => const ThankYouScreen(),
),
    ],
  );
}
