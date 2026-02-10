const router = require("express").Router();
const c = require("../controllers/comment.controller");
const { requireAuth, requireAdmin } = require("../middlewares/auth.middleware");

// public
router.get("/product/:productId", c.listByProduct);

// user
router.post("/product/:productId", requireAuth, c.create);

// admin
router.get("/", requireAuth, requireAdmin, c.listAll);
router.patch("/:id/reply", requireAuth, requireAdmin, c.reply);
router.patch("/:id/hide", requireAuth, requireAdmin, c.hide);

module.exports = router;
