const router = require("express").Router();
const c = require("../controllers/admin.controller");
const { requireAuth, requireAdmin } = require("../middlewares/auth.middleware");

router.get("/stats", requireAuth, requireAdmin, c.stats);

module.exports = router;
