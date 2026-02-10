const { fail } = require("../utils/response");

function notFound(req, res) {
  return fail(res, "Not found", 404);
}

function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  if (process.env.NODE_ENV !== "production") {
    console.error(err);
  }
  return fail(res, err.message || "Server error", status);
}

module.exports = { notFound, errorHandler };
