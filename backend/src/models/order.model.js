const mongoose = require("mongoose");

const OrderItemSchema = new mongoose.Schema({
  productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
  name: { type: String, required: true },
  image: { type: String, default: "" },
  // Chuyển sang String để hỗ trợ cả size số và size chữ (ví dụ: "42" hoặc "XL")
  size: { type: String, required: true }, 
  qty: { type: Number, required: true, min: 1 },
  price: { type: Number, required: true, min: 0 }
}, { _id: false });

const OrderSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  items: { type: [OrderItemSchema], required: true },
  total: { type: Number, required: true, min: 0 },

  // Thông tin giao hàng
  name: { type: String, required: true, trim: true }, 
  phone: { type: String, required: true, trim: true },
  address: { type: String, required: true, trim: true },
  
  paymentMethod: { type: String, enum: ["cod", "vnpay"], default: "cod" },
  status: { 
    type: String, 
    enum: ["pending", "confirmed", "shipping", "done", "cancelled"], 
    default: "pending" 
  },
  // Lưu thêm ghi chú của khách hàng nếu cần
  note: { type: String, default: "" } 
}, { timestamps: true });

module.exports = mongoose.model("Order", OrderSchema);