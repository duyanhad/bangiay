const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { ApiError } = require("../utils/apiError");
const User = require("../models/user.model");

// Hàm tạo Token
function signToken(user) {
  return jwt.sign(
    { id: user._id.toString(), role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );
}

// 1. Hàm Register
async function register({ email, password, name, phone, address }) {
  if (!email || !password) throw new ApiError("Email và mật khẩu là bắt buộc", 400);
  if (String(password).length < 6) throw new ApiError("Mật khẩu phải có ít nhất 6 ký tự", 400);

  const exists = await User.findOne({ email: String(email).toLowerCase() });
  if (exists) throw new ApiError("Email đã tồn tại", 409);

  const passwordHash = await bcrypt.hash(String(password), 10);
  
  // SỬA: Thêm phone và address vào lúc tạo user
  const user = await User.create({ 
    email, 
    passwordHash, 
    name: name || "", 
    phone: phone || "", 
    address: address || "" 
  });

  const token = signToken(user);
  return { 
    token, 
    user: { id: user._id, email: user.email, name: user.name, role: user.role, phone: user.phone, address: user.address } 
  };
}

// 2. Hàm Login
async function login({ email, password }) {
  if (!email || !password) throw new ApiError("Vui lòng nhập email và mật khẩu", 400);

  const user = await User.findOne({ email: String(email).toLowerCase() });
  if (!user) throw new ApiError("Thông tin đăng nhập không chính xác", 401);

  // [QUAN TRỌNG] Kiểm tra xem tài khoản có bị Admin khóa không
  if (user.isLocked) {
    throw new ApiError("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Admin.", 403);
  }

  const okPass = await bcrypt.compare(String(password), user.passwordHash);
  if (!okPass) throw new ApiError("Thông tin đăng nhập không chính xác", 401);

  const token = signToken(user);
  return { 
    token, 
    user: { id: user._id, email: user.email, name: user.name, role: user.role, phone: user.phone, address: user.address } 
  };
}

// 3. Hàm ME (Lấy thông tin cá nhân)
async function me(userId) {
  const user = await User.findById(userId).select("-passwordHash");
  if (!user) throw new ApiError("User not found", 404);
  
  // Kiểm tra lại lần nữa phòng trường hợp đang login thì bị khóa
  if (user.isLocked) {
    throw new ApiError("Tài khoản đã bị khóa", 403);
  }

  return user; // Trả về nguyên user object (đã trừ passwordHash)
}

// 4. Hàm Update Profile
async function updateProfile(userId, { name, phone, address }) {
  const user = await User.findById(userId);
  if (!user) throw new ApiError("User not found", 404);

  if (name !== undefined) user.name = name;
  if (phone !== undefined) user.phone = phone;
  if (address !== undefined) user.address = address;
  
  await user.save();
  return { id: user._id, email: user.email, name: user.name, role: user.role, phone: user.phone, address: user.address };
}

// 5. Hàm Change Password
async function changePassword(userId, { oldPassword, newPassword }) {
  if (!oldPassword || !newPassword) {
    throw new ApiError("Vui lòng nhập mật khẩu cũ và mới", 400);
  }

  if (String(newPassword).length < 6) {
    throw new ApiError("Mật khẩu mới phải có ít nhất 6 ký tự", 400);
  }

  const user = await User.findById(userId);
  if (!user) throw new ApiError("User not found", 404);

  const okPass = await bcrypt.compare(String(oldPassword), user.passwordHash);
  if (!okPass) throw new ApiError("Mật khẩu cũ không chính xác", 401);

  user.passwordHash = await bcrypt.hash(String(newPassword), 10);
  await user.save();

  return { message: "Đổi mật khẩu thành công" };
}

module.exports = { register, login, me, updateProfile, changePassword };