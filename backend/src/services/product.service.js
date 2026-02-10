const { ApiError } = require("../utils/apiError");
const Product = require("../models/product.model");

async function list(q) {
  const search = (q.search || "").trim();
  const brand = (q.brand || "").trim();
  const category = (q.category || "").trim();
  const minPrice = q.minPrice ? Number(q.minPrice) : null;
  const maxPrice = q.maxPrice ? Number(q.maxPrice) : null;
  const size = q.size ? Number(q.size) : null;

  const page = Math.max(1, Number(q.page || 1));
  const limit = Math.min(50, Math.max(1, Number(q.limit || 10)));
  const skip = (page - 1) * limit;

  const filter = { isActive: true };
  if (search) filter.name = { $regex: search, $options: "i" };
  if (brand) filter.brand = brand;
  if (category) filter.category = category;
  if (minPrice != null || maxPrice != null) {
    filter.price = {};
    if (minPrice != null) filter.price.$gte = minPrice;
    if (maxPrice != null) filter.price.$lte = maxPrice;
  }
  if (size != null) filter.variants = { $elemMatch: { size } };

  const [items, total] = await Promise.all([
    Product.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Product.countDocuments(filter)
  ]);

  return { data: items, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
}

async function detail(id) {
  const item = await Product.findById(id);
  if (!item || !item.isActive) throw new ApiError("Product not found", 404);
  return item;
}

async function create(payload) {
  if (!payload?.name || payload.price == null) throw new ApiError("name/price required", 400);
  return Product.create(payload);
}

async function update(id, payload) {
  const p = await Product.findByIdAndUpdate(id, payload, { new: true });
  if (!p) throw new ApiError("Product not found", 404);
  return p;
}

async function remove(id) {
  const p = await Product.findByIdAndUpdate(id, { isActive: false }, { new: true });
  if (!p) throw new ApiError("Product not found", 404);
  return p;
}

module.exports = { list, detail, create, update, remove };
