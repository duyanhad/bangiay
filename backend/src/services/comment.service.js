const { ApiError } = require("../utils/apiError");
const Comment = require("../models/comment.model");
const User = require("../models/user.model");

async function listByProduct(productId) {
  return Comment.find({ productId, isHidden: false }).sort({ createdAt: -1 });
}

async function create(userId, productId, { content, rating }) {
  if (!content || !String(content).trim()) throw new ApiError("Content required", 400);

  const user = await User.findById(userId).select("name email");
  if (!user) throw new ApiError("User not found", 404);

  return Comment.create({
    productId,
    userId,
    userName: user.name || user.email,
    content: String(content).trim(),
    rating: rating ? Number(rating) : undefined
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
  if (!content || !String(content).trim()) throw new ApiError("Reply content required", 400);
  const c = await Comment.findById(commentId);
  if (!c) throw new ApiError("Comment not found", 404);
  c.replies.push({ adminId, content: String(content).trim() });
  await c.save();
  return c;
}

async function hide(commentId, isHidden) {
  const c = await Comment.findByIdAndUpdate(commentId, { isHidden: !!isHidden }, { new: true });
  if (!c) throw new ApiError("Comment not found", 404);
  return c;
}

module.exports = { listByProduct, create, listAll, reply, hide };
