const router = require("express").Router();
const c = require("../controllers/order.controller");
const { requireAuth, requireAdmin } = require("../middlewares/auth.middleware");

// user
router.post("/", requireAuth, c.create);
router.get("/my", requireAuth, c.myOrders);

// admin
router.get("/", requireAuth, requireAdmin, c.listAll);
router.patch("/:id/status", requireAuth, requireAdmin, c.updateStatus);

module.exports = router;
