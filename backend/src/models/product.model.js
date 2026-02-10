const mongoose = require("mongoose");

const VariantSchema = new mongoose.Schema({
  size: { type: Number, required: true },
  stock: { type: Number, required: true, min: 0 }
}, { _id: false });

const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  brand: { type: String, default: "" },
  category: { type: String, default: "" },
  price: { type: Number, required: true, min: 0 },
  images: [{ type: String }],
  description: { type: String, default: "" },
  variants: { type: [VariantSchema], default: [] },
  soldCount: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model("Product", ProductSchema);
