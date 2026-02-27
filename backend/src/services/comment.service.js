const { ApiError } = require("../utils/apiError");
const Comment = require("../models/comment.model");
const User = require("../models/user.model");

async function listByProduct(productId) {
  // Lấy các bình luận không bị ẩn, sắp xếp mới nhất lên đầu
  return Comment.find({ productId, isHidden: false }).sort({ createdAt: -1 });
}

async function create(userId, productId, { content, rating, images }) {
  // Kiểm tra nội dung bình luận
  if (!content || !String(content).trim()) {
    throw new ApiError("Nội dung bình luận không được để trống", 400);
  }

  // Tìm thông tin người dùng để lấy tên hiển thị
  const user = await User.findById(userId).select("name email");
  if (!user) throw new ApiError("Người dùng không tồn tại", 404);

  // Lưu vào Database
  return Comment.create({
    productId,
    userId,
    userName: user.name || user.email,
    content: String(content).trim(),
    rating: rating ? Number(rating) : undefined,
    images: images || [] // ✅ Lưu mảng đường dẫn ảnh (VD: ["/uploads/abc.jpg"])
  });
}

async function listAll(q) {
  const filter = {};
  if (q.productId) filter.productId = q.productId;
  if (q.hidden === "true") filter.isHidden = true;
  if (q.hidden === "false") filter.isHidden = false;
  
  return Comment.find(filter).sort({ createdAt: -1 }).limit(200);
}

async function reply(adminId, commentId, content) {
  if (!content || !String(content).trim()) {
    throw new ApiError("Nội dung phản hồi không được để trống", 400);
  }
  
  const c = await Comment.findById(commentId);
  if (!c) throw new ApiError("Không tìm thấy bình luận", 404);
  
  c.replies.push({ adminId, content: String(content).trim() });
  await c.save();
  return c;
}

async function hide(commentId, isHidden) {
  const c = await Comment.findByIdAndUpdate(
    commentId, 
    { isHidden: !!isHidden }, 
    { new: true }
  );
  if (!c) throw new ApiError("Không tìm thấy bình luận", 404);
  return c;
}

module.exports = { listByProduct, create, listAll, reply, hide };