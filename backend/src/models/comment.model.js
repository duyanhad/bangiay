const mongoose = require("mongoose");

const ReplySchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  content: { type: String, required: true, trim: true }
}, { timestamps: true });

const CommentSchema = new mongoose.Schema({
  productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  userName: { type: String, default: "" },
  content: { type: String, required: true, trim: true },
  rating: { type: Number, min: 1, max: 5 }, 
  
  // ✅ Mảng lưu trữ các đường dẫn ảnh (Ví dụ: ["/uploads/image1.jpg", "/uploads/image2.jpg"])
  images: { 
    type: [String], 
    default: [] 
  }, 
  
  isHidden: { type: Boolean, default: false },
  replies: { type: [ReplySchema], default: [] }
}, { timestamps: true });

// Sắp xếp index để truy vấn theo sản phẩm nhanh hơn (Tùy chọn)
CommentSchema.index({ productId: 1, createdAt: -1 });

module.exports = mongoose.model("Comment", CommentSchema);