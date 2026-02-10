const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const svc = require("../services/order.service");

exports.create = asyncHandler(async (req, res) => ok(res, await svc.create(req.user.id, req.body)));
exports.myOrders = asyncHandler(async (req, res) => ok(res, await svc.myOrders(req.user.id)));

exports.listAll = asyncHandler(async (req, res) => ok(res, await svc.listAll()));
exports.updateStatus = asyncHandler(async (req, res) => ok(res, await svc.updateStatus(req.params.id, req.body.status)));
