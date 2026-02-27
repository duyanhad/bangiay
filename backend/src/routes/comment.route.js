const router = require("express").Router();
const c = require("../controllers/comment.controller");
const { requireAuth, requireAdmin } = require("../middlewares/auth.middleware");

// ✅ IMPORT MIDDLEWARE UPLOAD (Đảm bảo bạn đã tạo file này ở Bước 3)
const upload = require("../middlewares/upload.middleware");

// public
router.get("/product/:productId", c.listByProduct);

// user
// ✅ THÊM ROUTE NÀY: Cho phép upload tối đa 5 ảnh với key là 'images'
router.post("/upload", requireAuth, upload.array("images", 5), c.uploadImages);

router.post("/product/:productId", requireAuth, c.create);

// admin
router.get("/", requireAuth, requireAdmin, c.listAll);
router.patch("/:id/reply", requireAuth, requireAdmin, c.reply);
router.patch("/:id/hide", requireAuth, requireAdmin, c.hide);

module.exports = router;