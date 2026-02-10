const router = require("express").Router();
const c = require("../controllers/product.controller");
const { requireAuth, requireAdmin } = require("../middlewares/auth.middleware");

// public
router.get("/", c.list);
router.get("/:id", c.detail);

// admin
router.post("/", requireAuth, requireAdmin, c.create);
router.patch("/:id", requireAuth, requireAdmin, c.update);
router.delete("/:id", requireAuth, requireAdmin, c.remove);

module.exports = router;
