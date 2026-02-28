const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const adminSvc = require("../services/admin.service");

// ======================================================
// 1. DASHBOARD & STATS
// ======================================================
exports.getStats = asyncHandler(async (req, res) => {
  const overview = await adminSvc.getDashboardStats();
  const topProducts = await adminSvc.getTopSelling();

  let lowStock = [];
  try {
    lowStock = await adminSvc.getLowStock();
  } catch (e) {
    console.log("Service getLowStock chưa có, trả về rỗng");
  }

  const revenueChart = await adminSvc.getRevenueChart(req.query.type);

  const responseData = {
    ...overview,
    topSelling: topProducts,
    lowStock: lowStock,
    revenueChart: revenueChart,
  };

  ok(res, responseData);
});

// ======================================================
// 2. USERS MANAGEMENT
// ======================================================
exports.getUsers = asyncHandler(async (req, res) => {
  const { page, limit, search } = req.query;

  ok(
    res,
    await adminSvc.getAllUsers(
      Number(page) || 1,
      Number(limit) || 10,
      search
    )
  );
});

exports.lockUser = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.toggleUserLock(req.params.id));
});

exports.deleteUser = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.deleteUser(req.params.id));
});

// ======================================================
// 3. CATEGORIES MANAGEMENT
// ======================================================

// GET ALL
exports.getCategories = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.getAllCategories());
});

// CREATE
exports.createCategory = asyncHandler(async (req, res) => {
  const created = await adminSvc.createCategory(req.body);
  ok(res, created);
});

// UPDATE (FIXED PRO VERSION)
exports.updateCategory = asyncHandler(async (req, res) => {
  const updated = await adminSvc.updateCategory(
    req.params.id,
    req.body
  );

  if (!updated) {
    return res.status(404).json({
      message: "Category not found",
    });
  }

  ok(res, updated);
});

// DELETE (FIXED PRO VERSION)
exports.deleteCategory = asyncHandler(async (req, res) => {
  const deleted = await adminSvc.deleteCategory(
    req.params.id
  );

  if (!deleted) {
    return res.status(404).json({
      message: "Category not found",
    });
  }

  ok(res, deleted);
});

// ======================================================
// 4. ORDERS MANAGEMENT
// ======================================================
exports.getOrders = asyncHandler(async (req, res) => {
  const { page, limit, status } = req.query;
  ok(res, await adminSvc.getAllOrders(
      Number(page) || 1, 
      Number(limit) || 20, // ✅ Cố định 20 đơn 1 lần
      status
  ));
});
const commentSvc = require("../services/comment.service");

exports.getComments = asyncHandler(async (req, res) => {
  // Lấy tất cả bình luận (bao gồm cả bị ẩn) để admin quản lý
  const comments = await commentSvc.listAll(req.query);
  ok(res, comments);
});

exports.replyComment = asyncHandler(async (req, res) => {
  const result = await commentSvc.reply(req.user.id, req.params.id, req.body.content);
  ok(res, result);
});

exports.hideComment = asyncHandler(async (req, res) => {
  const result = await commentSvc.hide(req.params.id, req.body.isHidden);
  ok(res, result);
});

exports.deleteComment = asyncHandler(async (req, res) => {
  const Comment = require("../models/comment.model");
  await Comment.findByIdAndDelete(req.params.id);
  ok(res, { message: "Xóa thành công" });
});
exports.getOrderDetails = asyncHandler(async (req, res) => {
  ok(res, await adminSvc.getOrderDetails(req.params.id));
});
exports.getProducts = asyncHandler(async (req, res) => {
  const products = await adminSvc.getAllProductsAdmin();
  ok(res, products);
});
exports.updateOrderStatus = asyncHandler(async (req, res) => {
  ok(
    res,
    await adminSvc.updateOrderStatus(
      req.params.id,
      req.body.status
    )
  );
});