const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const svc = require("../services/product.service");

exports.list = asyncHandler(async (req, res) => {
  const { data, meta } = await svc.list(req.query);
  return ok(res, data, meta);
});
exports.detail = asyncHandler(async (req, res) => ok(res, await svc.detail(req.params.id)));

exports.create = asyncHandler(async (req, res) => ok(res, await svc.create(req.body)));
exports.update = asyncHandler(async (req, res) => ok(res, await svc.update(req.params.id, req.body)));
exports.remove = asyncHandler(async (req, res) => ok(res, await svc.remove(req.params.id)));
