const router = require("express").Router();
const c = require("../controllers/admin.controller");
const { requireAuth, requireAdmin } = require("../middlewares/auth.middleware");

// Middleware chặn: Phải là Admin mới vào được các API dưới
router.use(requireAuth, requireAdmin);

// 1. Dashboard & Thống kê
router.get("/stats", c.getStats); // Trả về overview, chart, top selling

// 2. Quản lý Users
router.get("/users", c.getUsers);
router.put("/users/:id/lock", c.lockUser); // API khóa/mở khóa
router.delete("/users/:id", c.deleteUser);

// 3. Quản lý Categories
router.get("/categories", c.getCategories);
router.post("/categories", c.createCategory);
router.delete("/categories/:id", c.deleteCategory);

// 4. Quản lý Orders
router.get("/orders", c.getOrders); // ?page=1&status=pending
router.get("/orders/:id", c.getOrderDetails);
router.put("/orders/:id/status", c.updateOrderStatus);
router.get("/products", c.getProducts);
// Quản lý bình luận (Đã có middleware requireAdmin ở đầu file)
router.get("/comments", c.getComments); // Lấy tất cả comment để quản lý
router.patch("/comments/:id/reply", c.replyComment); // Admin rep
router.patch("/comments/:id/hide", c.hideComment); // Ẩn/Hiện
router.delete("/comments/:id", c.deleteComment); // Xóa vĩnh viễn

module.exports = router;