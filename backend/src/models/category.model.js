const mongoose = require("mongoose");

const CategorySchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true, trim: true },
  image: { type: String, default: "" }, // Link ảnh icon nếu cần
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model("Category", CategorySchema);