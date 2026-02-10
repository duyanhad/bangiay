const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { ApiError } = require("../utils/apiError");
const User = require("../models/user.model");

function signToken(user) {
  return jwt.sign(
    { id: user._id.toString(), role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );
}

async function register({ email, password, name }) {
  if (!email || !password) throw new ApiError("Email/password required", 400);
  if (String(password).length < 6) throw new ApiError("Password must be at least 6 chars", 400);

  const exists = await User.findOne({ email: String(email).toLowerCase() });
  if (exists) throw new ApiError("Email already exists", 409);

  const passwordHash = await bcrypt.hash(String(password), 10);
  const user = await User.create({ email, passwordHash, name: name || "" });

  const token = signToken(user);
  return { token, user: { id: user._id, email: user.email, name: user.name, role: user.role } };
}

async function login({ email, password }) {
  if (!email || !password) throw new ApiError("Email/password required", 400);

  const user = await User.findOne({ email: String(email).toLowerCase() });
  if (!user) throw new ApiError("Invalid credentials", 401);

  const okPass = await bcrypt.compare(String(password), user.passwordHash);
  if (!okPass) throw new ApiError("Invalid credentials", 401);

  const token = signToken(user);
  return { token, user: { id: user._id, email: user.email, name: user.name, role: user.role } };
}

async function me(userId) {
  const user = await User.findById(userId).select("email name role");
  if (!user) throw new ApiError("User not found", 404);
  return { id: user._id, email: user.email, name: user.name, role: user.role };
}

module.exports = { register, login, me };
