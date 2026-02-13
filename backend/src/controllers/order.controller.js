const { asyncHandler } = require('../utils/asyncHandler');

const { ok } = require("../utils/response");
const svc = require("../services/order.service");

// ===== CREATE ORDER =====
exports.create = asyncHandler(async (req, res) => {
  const result = await svc.create(req.user.id, req.body);
  ok(res, result);
});

// ===== USER ORDERS =====
exports.myOrders = asyncHandler(async (req, res) => {
  const result = await svc.myOrders(req.user.id);
  ok(res, result);
});

// ===== ADMIN LIST =====
exports.listAll = asyncHandler(async (req, res) => {
  const result = await svc.listAll();
  ok(res, result);
});

// ===== UPDATE STATUS =====
exports.updateStatus = asyncHandler(async (req, res) => {
  const result = await svc.updateStatus(req.params.id, req.body.status);
  ok(res, result);
});

// ===== VNPAY CREATE PAYMENT =====
exports.createVnpayPayment = asyncHandler(async (req, res) => {
  const paymentUrl = await svc.createVnpayPayment(req.user.id, req.body);
  ok(res, paymentUrl);
});

// ===== VNPAY RETURN =====
exports.vnpayReturn = asyncHandler(async (req, res) => {
  const result = await svc.vnpayReturn(req.query);
  ok(res, result);
});