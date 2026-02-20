const mongoose = require("mongoose");

const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  brand: { type: String, default: "" },
  category: { type: String, default: "" },
  price: { type: Number, required: true, min: 0 },
  discount: { type: Number, default: 0 },
  final_price: { type: Number, default: 0 },
  images: [{ type: String }],
  description: { type: String, default: "" },

  // ✅ 1. BẮT BUỘC PHẢI CÓ 'stock' (Tổng tồn kho của tất cả các size)
  // Để Admin Dashboard tính toán và Order Service check nhanh xem còn hàng không
  stock: { type: Number, default: 0 },

  // ✅ 2. Quản lý chi tiết từng size (Optional nhưng database bạn đang dùng)
  // Ví dụ: { "S": 10, "M": 15, "L": 5 }
  size_stocks: { type: Object, default: {} },
  
  // Dùng để hiển thị danh sách size cho khách chọn
  sizes: { type: [String], default: [] }, 

  // Field cũ (nếu muốn giữ để tương thích ngược, không thì bỏ cũng được)
  variants: { type: Array, default: [] }, 

  // ✅ 3. Số lượng đã bán (Quan trọng cho Top Selling)
  soldCount: { type: Number, default: 0 },
  
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model("Product", ProductSchema);