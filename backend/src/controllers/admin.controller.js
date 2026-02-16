const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const adminSvc = require("../services/admin.service");

// --- 1. DASHBOARD & STATS ---
exports.getStats = asyncHandler(async (req, res) => {
  // B1: Lấy các luồng dữ liệu từ Service
  const overview = await adminSvc.getDashboardStats(); 
  // overview chứa: { productCount, orderCount, revenue, totalStock }

  const topProducts = await adminSvc.getTopSelling();
  
  // Lưu ý: Nếu service chưa có hàm getLowStock, bạn cần thêm vào service (xem hướng dẫn bên dưới)
  // Nếu chưa có, tạm thời để mảng rỗng [] để không lỗi App
  let lowStock = [];
  try {
    lowStock = await adminSvc.getLowStock();
  } catch (e) {
    console.log("Service getLowStock chưa có, trả về rỗng");
  }

  const revenueChart = await adminSvc.getRevenueChart(req.query.type);

  // B2: Gộp dữ liệu thành 1 object phẳng (Flat) để Flutter dễ đọc
  // Flutter AdminStats cần: { productCount, revenue, topSelling, lowStock... }
  const responseData = {
    ...overview,             // Rã các biến productCount, revenue... ra ngoài cùng
    topSelling: topProducts, // Đổi tên 'topProducts' -> 'topSelling' cho khớp Flutter
    lowStock: lowStock,      // Thêm danh sách sắp hết hàng
    revenueChart: revenueChart // (Optional) Gửi kèm nếu sau này cần vẽ biểu đồ
  };

  ok(res, responseData);
});

// --- 2. USERS MANAGEMENT ---
exports.getUsers = asyncHandler(async (req, res) => {
  const { page, limit, search } = req.query;
  // Ép kiểu Number để tránh lỗi phân trang
  ok(res, await adminSvc.getAllUsers(Number(page) || 1, Number(limit) || 10, search));
});

exports.lockUser = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.toggleUserLock(req.params.id));
});

exports.deleteUser = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.deleteUser(req.params.id));
});

// --- 3. CATEGORIES MANAGEMENT ---
exports.getCategories = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.getAllCategories());
});

exports.createCategory = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.createCategory(req.body));
});

exports.deleteCategory = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.deleteCategory(req.params.id));
});

// --- 4. ORDERS MANAGEMENT ---
exports.getOrders = asyncHandler(async (req, res) => {
  const { page, limit, status } = req.query;
  ok(res, await adminSvc.getAllOrders(Number(page) || 1, Number(limit) || 10, status));
});

exports.getOrderDetails = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.getOrderDetails(req.params.id));
});

exports.updateOrderStatus = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.updateOrderStatus(req.params.id, req.body.status));
});