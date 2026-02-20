const { ApiError } = require("../utils/apiError");
const Product = require("../models/product.model");

// ======================================================
// LIST
// ======================================================
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

  // 🔥 FIX FILTER SIZE (chỉ lấy size còn hàng)
  if (size != null) {
    filter.variants = {
      $elemMatch: {
        size: Number(size),
        stock: { $gt: 0 }
      }
    };
  }

  const [items, total] = await Promise.all([
    Product.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Product.countDocuments(filter),
  ]);

  return {
    data: items,
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

// ======================================================
// DETAIL
// ======================================================
async function detail(id) {
  const item = await Product.findById(id);
  if (!item || !item.isActive)
    throw new ApiError("Product not found", 404);

  return item;
}

// ======================================================
// CREATE
// ======================================================
async function create(payload) {
  if (!payload?.name || payload.price == null)
    throw new ApiError("name/price required", 400);

  // 🔥 Chuẩn hóa variants
  let variants = [];
  if (Array.isArray(payload.variants)) {
    variants = payload.variants.map(v => {
      const size = Number(v.size);
      const stock = Number(v.stock);

      if (isNaN(size) || isNaN(stock) || stock < 0)
        throw new ApiError("Invalid size or stock", 400);

      return { size, stock };
    });
  }

  const totalStock = variants.reduce((sum, v) => sum + v.stock, 0);

  const price = Number(payload.price || 0);
  const discount = Number(payload.discount || 0);
  const final_price = price - (price * discount) / 100;

  return Product.create({
    ...payload,
    variants,
    sizes: variants.map(v => String(v.size)),
    stock: totalStock,
    final_price
  });
}

// ======================================================
// UPDATE
// ======================================================
async function update(id, payload) {
  const product = await Product.findById(id);
  if (!product) throw new ApiError("Product not found", 404);

  // --- Basic fields ---
  if (payload.name !== undefined) product.name = payload.name;
  if (payload.description !== undefined) product.description = payload.description;
  if (payload.brand !== undefined) product.brand = payload.brand;
  if (payload.category !== undefined) product.category = payload.category;

  if (payload.price !== undefined)
    product.price = Number(payload.price);

  if (payload.discount !== undefined)
    product.discount = Number(payload.discount);

  if (payload.images !== undefined)
    product.images = payload.images;

  // 🔥 UPDATE VARIANTS
  if (Array.isArray(payload.variants)) {

    const cleanVariants = payload.variants.map(v => {
      const size = Number(v.size);
      const stock = Number(v.stock);

      if (isNaN(size) || isNaN(stock) || stock < 0)
        throw new ApiError("Invalid size or stock", 400);

      return { size, stock };
    });

    product.variants = cleanVariants;

    // Auto update stock
    product.stock = cleanVariants.reduce(
      (sum, v) => sum + v.stock,
      0
    );

    // Sync sizes
    product.sizes = cleanVariants.map(v => String(v.size));
  }

  // 🔥 LUÔN TÍNH LẠI FINAL PRICE
  const price = Number(product.price || 0);
  const discount = Number(product.discount || 0);
  product.final_price = price - (price * discount) / 100;

  await product.save();
  return product;
}

// ======================================================
// SOFT DELETE
// ======================================================
async function remove(id) {
  const p = await Product.findByIdAndUpdate(
    id,
    { isActive: false },
    { new: true }
  );

  if (!p) throw new ApiError("Product not found", 404);
  return p;
}

module.exports = { list, detail, create, update, remove };