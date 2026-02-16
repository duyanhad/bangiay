const Cart = require("../models/cart.model");
const Product = require("../models/product.model");

exports.getCart = async (userId) => {
  // Luôn populate sản phẩm để lấy name và image hiển thị lên Flutter
  let cart = await Cart.findOne({ user: userId }).populate("items.product");
  if (!cart) {
    cart = await Cart.create({ user: userId, items: [] });
  }
  return cart;
};

exports.addToCart = async (userId, productId, quantity, size) => {
  const product = await Product.findById(productId);
  if (!product) throw new Error("Product not found");

  let cart = await Cart.findOne({ user: userId });
  if (!cart) cart = new Cart({ user: userId, items: [] });

  // Tìm sản phẩm cùng ID VÀ cùng Size
  const itemIndex = cart.items.findIndex(
    (item) => item.product.toString() === productId && item.size === size
  );

  if (itemIndex > -1) {
    cart.items[itemIndex].quantity += quantity;
  } else {
    cart.items.push({
      product: product._id,
      quantity: quantity,
      size: size, // [LƯU SIZE Ở ĐÂY]
      price: product.final_price || product.price,
      name: product.name,
      image: product.thumb
    });
  }
  return await cart.save();
};

exports.updateQuantity = async (userId, productId, quantity) => {
  const cart = await Cart.findOne({ user: userId });
  if (!cart) throw new Error("Cart not found");

  const itemIndex = cart.items.findIndex(
    (item) => item.product.toString() === productId
  );

  if (itemIndex > -1) {
    if (quantity <= 0) {
      cart.items.splice(itemIndex, 1);
    } else {
      cart.items[itemIndex].quantity = quantity;
    }
    return await cart.save();
  }
  throw new Error("Item not found in cart");
};

exports.removeItem = async (userId, productId) => {
  const cart = await Cart.findOne({ user: userId });
  if (!cart) throw new Error("Cart not found");

  cart.items = cart.items.filter(
    (item) => item.product.toString() !== productId
  );

  return await cart.save();
};