class Endpoints {
  // AUTH
  static const login = "/auth/login";
  static const register = "/auth/register";

  // CUSTOMER
  static const brands = "/api/brands";
  static const products = "/api/products";
  static const orders = "/api/orders";

  // ADMIN
  static const adminOrders = "/api/admin/orders";
  static const adminUsers = "/api/admin/users";
  static String blockUser(String id) => "/api/admin/users/$id/block";
  static const adminInventory = "/api/admin/inventory";
  static const updateStock = "/api/admin/inventory/update-stock";
  static const updateSize = "/api/admin/inventory/update-size";
}
