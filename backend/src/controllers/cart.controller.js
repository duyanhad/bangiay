const Cart = require("../models/cart.model");
const Product = require("../models/product.model");
const { asyncHandler } = require("../utils/asyncHandler");

const calcTotals = (cart) => {
  let total = 0;
  if (cart && cart.items) {
    cart.items.forEach((item) => {
      if (item.selected) {
        const price = item.price || (item.product ? item.product.price : 0);
        total += price * item.quantity;
      }
    });
  }
  return total;
};

exports.getMyCart = asyncHandler(async (req, res) => {
  let cart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  if (!cart) {
    cart = await Cart.create({ user: req.user._id, items: [] });
  }
  res.json({ ok: true, cart, total: calcTotals(cart) });
});

exports.addItem = asyncHandler(async (req, res) => {
  const { productId, quantity = 1 } = req.body;
  const qty = Number(quantity);

  const product = await Product.findById(productId);
  if (!product) return res.status(404).json({ ok: false, message: "Không tìm thấy SP" });

  let cart = await Cart.findOne({ user: req.user._id });
  if (!cart) {
    cart = new Cart({ user: req.user._id, items: [] });
  }

  const itemIndex = cart.items.findIndex(item => 
    item.product && item.product.toString() === productId.toString()
  );

  if (itemIndex > -1) {
    cart.items[itemIndex].quantity += qty;
  } else {
    cart.items.push({
      product: productId,
      quantity: qty,
      price: product.price,
      selected: true
    });
  }

  // 🔥 LỆNH QUAN TRỌNG: Báo cho Mongoose biết mảng items đã thay đổi để lưu thật sự
  cart.markModified('items'); 
  await cart.save();
  
  const fullCart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  res.json({ ok: true, cart: fullCart, total: calcTotals(fullCart) });
});

exports.updateItem = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { quantity } = req.body;
  const cart = await Cart.findOne({ user: req.user._id });
  
  const itemIndex = cart.items.findIndex(i => i.product.toString() === productId);
  if (itemIndex > -1) {
    if (Number(quantity) <= 0) {
      cart.items.splice(itemIndex, 1);
    } else {
      cart.items[itemIndex].quantity = Number(quantity);
    }
    cart.markModified('items');
    await cart.save();
  }
  const fullCart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  res.json({ ok: true, cart: fullCart, total: calcTotals(fullCart) });
});

exports.toggleSelect = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const cart = await Cart.findOne({ user: req.user._id });
  const item = cart.items.find(i => i.product.toString() === productId);
  if (item) {
    item.selected = !item.selected;
    cart.markModified('items');
    await cart.save();
  }
  const fullCart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  res.json({ ok: true, cart: fullCart, total: calcTotals(fullCart) });
});

exports.removeItem = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const cart = await Cart.findOne({ user: req.user._id });
  if (cart) {
    cart.items = cart.items.filter(i => i.product.toString() !== productId);
    cart.markModified('items');
    await cart.save();
  }
  const fullCart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  res.json({ ok: true, cart: fullCart, total: calcTotals(fullCart) });
});

exports.clearCart = asyncHandler(async (req, res) => {
  const cart = await Cart.findOne({ user: req.user._id });
  if (cart) {
    cart.items = [];
    cart.markModified('items');
    await cart.save();
  }
  res.json({ ok: true, cart: { items: [] }, total: 0 });
});