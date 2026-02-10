const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const svc = require("../services/comment.service");

exports.listByProduct = asyncHandler(async (req, res) => ok(res, await svc.listByProduct(req.params.productId)));
exports.create = asyncHandler(async (req, res) => ok(res, await svc.create(req.user.id, req.params.productId, req.body)));

exports.listAll = asyncHandler(async (req, res) => ok(res, await svc.listAll(req.query)));
exports.reply = asyncHandler(async (req, res) => ok(res, await svc.reply(req.user.id, req.params.id, req.body.content)));
exports.hide = asyncHandler(async (req, res) => ok(res, await svc.hide(req.params.id, req.body.isHidden)));
