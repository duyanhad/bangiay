const mongoose = require("mongoose");

const cartItemSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Product",
    required: true
  },
  // [QUAN TRỌNG]: Thêm size vào đây để lưu lựa chọn của khách
  size: {
    type: String, 
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    min: 1
  },
  price: Number, // snapshot price lúc add
  name: String,  // Lưu tên để hiện nhanh ở Cart
  image: String, // Lưu ảnh để hiện nhanh ở Cart
  selected: {
    type: Boolean,
    default: true
  }
});

const cartSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      unique: true
    },
    items: [cartItemSchema]
  },
  { timestamps: true }
);

module.exports = mongoose.model("Cart", cartSchema);