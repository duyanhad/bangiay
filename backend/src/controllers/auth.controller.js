const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const svc = require("../services/auth.service");

exports.register = asyncHandler(async (req, res) => ok(res, await svc.register(req.body)));
exports.login = asyncHandler(async (req, res) => ok(res, await svc.login(req.body)));
exports.me = asyncHandler(async (req, res) => ok(res, await svc.me(req.user.id)));
exports.updateProfile = asyncHandler(async (req, res) => ok(res, await svc.updateProfile(req.user.id, req.body)));
exports.changePassword = asyncHandler(async (req, res) => ok(res, await svc.changePassword(req.user.id, req.body)));