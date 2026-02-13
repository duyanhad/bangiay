const router = require("express").Router();

router.use("/auth", require("./auth.route"));
router.use("/products", require("./product.route"));
router.use("/orders", require("./order.route"));
router.use("/comments", require("./comment.route"));
router.use("/admin", require("./admin.route"));
router.use("/cart", require("./cart.route"));
module.exports = router;
