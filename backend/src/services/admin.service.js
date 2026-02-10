const Product = require("../models/product.model");
const Order = require("../models/order.model");
const Comment = require("../models/comment.model");

async function stats() {
  const [productCount, orderCount] = await Promise.all([
    Product.countDocuments(),
    Order.countDocuments()
  ]);

  const revenueAgg = await Order.aggregate([
    { $match: { status: { $in: ["confirmed", "shipping", "done"] } } },
    { $group: { _id: null, revenue: { $sum: "$total" } } }
  ]);
  const revenue = revenueAgg[0]?.revenue || 0;

  const products = await Product.find().select("variants name soldCount price");
  let totalStock = 0;
  const lowStock = [];
  for (const p of products) {
    const stock = (p.variants || []).reduce((s, v) => s + (v.stock || 0), 0);
    totalStock += stock;
    if (stock <= 3) lowStock.push({ id: p._id, name: p.name, stock });
  }

  const topSelling = await Product.find().sort({ soldCount: -1 }).limit(5).select("name soldCount price");
  const unansweredComments = await Comment.countDocuments({ "replies.0": { $exists: false }, isHidden: false });

  return { productCount, orderCount, revenue, totalStock, lowStock, topSelling, unansweredComments };
}

module.exports = { stats };
