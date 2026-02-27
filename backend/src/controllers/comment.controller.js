const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const svc = require("../services/comment.service");

exports.listByProduct = asyncHandler(async (req, res) => ok(res, await svc.listByProduct(req.params.productId)));
exports.create = asyncHandler(async (req, res) => ok(res, await svc.create(req.user.id, req.params.productId, req.body)));

exports.listAll = asyncHandler(async (req, res) => ok(res, await svc.listAll(req.query)));
exports.reply = asyncHandler(async (req, res) => ok(res, await svc.reply(req.user.id, req.params.id, req.body.content)));
exports.hide = asyncHandler(async (req, res) => ok(res, await svc.hide(req.params.id, req.body.isHidden)));

// ✅ THÊM HÀM NÀY ĐỂ XỬ LÝ UPLOAD ẢNH
exports.uploadImages = asyncHandler(async (req, res) => {
  // req.files chứa các file ảnh đã được multer lưu lại
  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ ok: false, message: "Không có ảnh nào được tải lên" });
  }

  // Tạo mảng đường dẫn public để app có thể hiển thị (ví dụ: /uploads/abcxyz.jpg)
  const imageUrls = req.files.map(file => `/uploads/${file.filename}`);
  
  // Trả về mảng url ảnh
  return ok(res, imageUrls); 
});