const { asyncHandler } = require("../utils/asyncHandler");
const { ok } = require("../utils/response");
const adminSvc = require("../services/admin.service");

exports.stats = asyncHandler(async (req, res) => ok(res, await adminSvc.stats()));
