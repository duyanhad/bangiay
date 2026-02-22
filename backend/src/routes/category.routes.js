const express = require("express");
const router = express.Router();
const controller = require("../controllers/category.controller");

router.get("/", controller.getAllCategories);
router.post("/", controller.createCategory);
router.put("/:id", controller.updateCategory);
router.delete("/:id", controller.deleteCategory);

module.exports = router;