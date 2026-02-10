const jwt = require("jsonwebtoken");
const { ApiError } = require("../utils/apiError");

function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!token) return next(new ApiError("Unauthorized", 401));

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = payload; // {id, role}
    return next();
  } catch {
    return next(new ApiError("Invalid token", 401));
  }
}

function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== "admin") {
    return next(new ApiError("Forbidden", 403));
  }
  return next();
}

module.exports = { requireAuth, requireAdmin };
