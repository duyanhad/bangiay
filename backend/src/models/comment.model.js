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
  rating: { type: Number, min: 1, max: 5 }, // optional
  isHidden: { type: Boolean, default: false },
  replies: { type: [ReplySchema], default: [] }
}, { timestamps: true });

module.exports = mongoose.model("Comment", CommentSchema);
