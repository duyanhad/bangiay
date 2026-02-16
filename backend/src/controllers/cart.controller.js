const Cart = require("../models/cart.model");
const Product = require("../models/product.model");
const { asyncHandler } = require("../utils/asyncHandler");

// Tính tổng tiền dựa trên các món được tích chọn (Sử dụng giá snapshot)
const calcTotals = (cart) => {
  let total = 0;
  if (cart && cart.items) {
    cart.items.forEach((item) => {
      if (item.selected) {
        // Ưu tiên dùng giá price đã lưu trong giỏ hàng để ổn định đơn giá
        const price = item.price || 0; 
        total += price * item.quantity;
      }
    });
  }
  return total;
};

// Lấy giỏ hàng
exports.getMyCart = asyncHandler(async (req, res) => {
  let cart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  if (!cart) {
    cart = await Cart.create({ user: req.user._id, items: [] });
  }
  res.json({ ok: true, cart, total: calcTotals(cart) });
});

// Thêm vào giỏ hàng (Phân biệt theo Size)
exports.addItem = asyncHandler(async (req, res) => {
  const { productId, quantity = 1, size } = req.body;
  const qty = Number(quantity);

  if (!size) {
    return res.status(400).json({ ok: false, message: "Vui lòng chọn size sản phẩm" });
  }

  const product = await Product.findById(productId);
  if (!product) return res.status(404).json({ ok: false, message: "Không tìm thấy sản phẩm" });

  let cart = await Cart.findOne({ user: req.user._id });
  if (!cart) {
    cart = new Cart({ user: req.user._id, items: [] });
  }

  // Tìm sản phẩm trùng cả ID và Size
  const itemIndex = cart.items.findIndex(item => 
    item.product && 
    item.product.toString() === productId.toString() && 
    item.size === size.toString()
  );

  if (itemIndex > -1) {
    cart.items[itemIndex].quantity += qty;
  } else {
    cart.items.push({
      product: productId,
      quantity: qty,
      size: size.toString(),
      price: product.final_price || product.price, // Snapshot giá tại thời điểm thêm
      name: product.name,   
      image: product.thumb, 
      selected: true
    });
  }

  cart.markModified('items'); 
  await cart.save();
  
  const fullCart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  res.json({ ok: true, cart: fullCart, total: calcTotals(fullCart) });
});

// Cập nhật số lượng (Dựa trên productId và size)
exports.updateItem = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { quantity, size } = req.body; 
  
  const cart = await Cart.findOne({ user: req.user._id });
  if (!cart) return res.status(404).json({ ok: false, message: "Giỏ hàng không tồn tại" });
  
  const itemIndex = cart.items.findIndex(i => 
    i.product.toString() === productId && i.size === size?.toString()
  );

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

// Bật/Tắt chọn sản phẩm (ĐÃ SỬA LỖI .json())
exports.toggleSelect = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { size } = req.body; 
  
  const cartData = await Cart.findOne({ user: req.user._id });
  if (!cartData) return res.status(404).json({ ok: false, message: "Giỏ hàng không tồn tại" });

  const item = cartData.items.find(i => 
    i.product.toString() === productId && i.size === size?.toString()
  );

  if (item) {
    item.selected = !item.selected;
    cartData.markModified('items');
    await cartData.save();
  }
  
  const fullCart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  res.json({ ok: true, cart: fullCart, total: calcTotals(fullCart) });
});

// Xóa 1 dòng sản phẩm (productId + size)
exports.removeItem = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { size } = req.query; 
  
  const cart = await Cart.findOne({ user: req.user._id });
  if (cart) {
    cart.items = cart.items.filter(i => 
      !(i.product.toString() === productId && i.size === size?.toString())
    );
    cart.markModified('items');
    await cart.save();
  }
  
  const fullCart = await Cart.findOne({ user: req.user._id }).populate("items.product");
  res.json({ ok: true, cart: fullCart, total: calcTotals(fullCart) });
});

// Xóa sạch giỏ hàng
exports.clearCart = asyncHandler(async (req, res) => {
  const cart = await Cart.findOne({ user: req.user._id });
  if (cart) {
    cart.items = [];
    cart.markModified('items');
    await cart.save();
  }
  res.json({ ok: true, cart: { items: [] }, total: 0 });
});