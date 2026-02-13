const mongoose = require("mongoose");

const OrderItemSchema = new mongoose.Schema({
  productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
  name: { type: String, required: true },
  image: { type: String, default: "" },
  size: { type: Number, required: true },
  qty: { type: Number, required: true, min: 1 },
  price: { type: Number, required: true, min: 0 }
}, { _id: false });

const OrderSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  items: { type: [OrderItemSchema], required: true },
  total: { type: Number, required: true, min: 0 },
  // [NEW] Thêm trường này:
  paymentMethod: { type: String, enum: ["cod", "vnpay"], default: "cod" },
  status: { type: String, enum: ["pending", "confirmed", "shipping", "done", "cancelled"], default: "pending" }
}, { timestamps: true });

module.exports = mongoose.model("Order", OrderSchema);