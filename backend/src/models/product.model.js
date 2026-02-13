const mongoose = require("mongoose");

const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  brand: { type: String, default: "" },
  category: { type: String, default: "" },
  price: { type: Number, required: true, min: 0 },
  images: [{ type: String }],
  description: { type: String, default: "" },
  
  // SỬA Ở ĐÂY: Thêm 2 trường này để khớp với Database thực tế
  sizes: { type: [String], default: [] }, 
  size_stocks: { type: Object, default: {} },
  
  // Có thể giữ lại variants nếu bạn muốn dùng song song, nhưng DB hiện tại đang dùng 2 cái trên
  variants: { type: Array, default: [] }, 
  
  soldCount: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model("Product", ProductSchema);