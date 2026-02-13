const router = require("express").Router();
const ctrl = require("../controllers/cart.controller");
const { requireAuth } = require("../middlewares/auth.middleware");

router.get("/", requireAuth, ctrl.getMyCart);
router.post("/add", requireAuth, ctrl.addItem);
router.put("/item/:productId", requireAuth, ctrl.updateItem);
router.patch("/select/:productId", requireAuth, ctrl.toggleSelect);
router.delete("/item/:productId", requireAuth, ctrl.removeItem);
router.delete("/clear", requireAuth, ctrl.clearCart);

module.exports = router;