const { ApiError } = require("../utils/apiError");
const Order = require("../models/order.model");
const Product = require("../models/product.model");

async function create(userId, payload) {
  const items = payload?.items;
  if (!Array.isArray(items) || items.length === 0) throw new ApiError("Items required", 400);

  let total = 0;
  const normalized = [];

  for (const it of items) {
    const { productId, size, qty } = it;
    if (!productId || !size || !qty) throw new ApiError("Invalid item", 400);

    const p = await Product.findById(productId);
    if (!p) throw new ApiError("Product not found", 404);

    const v = p.variants.find(x => x.size === Number(size));
    if (!v) throw new ApiError("Size not available", 400);
    if (v.stock < Number(qty)) throw new ApiError("Out of stock", 400);

    total += p.price * Number(qty);
    normalized.push({
      productId: p._id,
      name: p.name,
      image: p.images?.[0] || "",
      size: Number(size),
      qty: Number(qty),
      price: p.price
    });

    v.stock -= Number(qty);
    p.soldCount += Number(qty);
    await p.save();
  }

  return Order.create({ userId, items: normalized, total });
}

async function myOrders(userId) {
  return Order.find({ userId }).sort({ createdAt: -1 });
}

async function listAll() {
  return Order.find().sort({ createdAt: -1 });
}

async function updateStatus(id, status) {
  const allowed = ["pending", "confirmed", "shipping", "done", "cancelled"];
  if (!allowed.includes(status)) throw new ApiError("Invalid status", 400);
  const o = await Order.findByIdAndUpdate(id, { status }, { new: true });
  if (!o) throw new ApiError("Order not found", 404);
  return o;
}

module.exports = { create, myOrders, listAll, updateStatus };
