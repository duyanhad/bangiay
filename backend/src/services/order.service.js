const { ApiError } = require("../utils/apiError");
const Order = require("../models/order.model");
const Product = require("../models/product.model");
const Cart = require("../models/cart.model"); 

const qs = require("qs");
const crypto = require("crypto");
const moment = require("moment");

/**
 * 1. TẠO ĐƠN HÀNG
 * ⚠️ Logic: Chỉ TRỪ KHO (giữ slot), CHƯA cộng số lượng đã bán.
 */
async function create(userId, payload) {
  console.log("--- DEBUG: Bắt đầu tạo đơn hàng ---");

  // 1. Lấy dữ liệu
  const items = payload.items || payload.cartItems || payload.products;
  const name = payload.name || payload.fullName || payload.receiverName;
  const phone = payload.phone || payload.phoneNumber || payload.phone_number;
  const address = payload.address || payload.shippingAddress;
  const paymentMethod = payload.paymentMethod || "cod";
  const note = payload.note || "";

  // 2. Validate
  if (!Array.isArray(items) || items.length === 0) {
    throw new ApiError("Danh sách sản phẩm không được trống", 400);
  }
  if (!name || !phone || !address) {
    throw new ApiError("Vui lòng nhập đầy đủ Họ tên, SĐT và Địa chỉ", 400);
  }

  let total = 0;
  const normalizedItems = [];

  // 3. Xử lý từng sản phẩm
  for (const item of items) {
    const { productId, size, qty } = item;
    const quantity = Number(qty);

    const product = await Product.findById(productId);
    if (!product) throw new ApiError(`Sản phẩm ID ${productId} không tồn tại`, 404);

    // --- CHECK KHO ---
    if (product.stock < quantity) {
       throw new ApiError(`Sản phẩm "${product.name}" đã hết hàng tổng.`, 400);
    }

    // Check kho theo Size
    if (size && product.size_stocks && product.size_stocks[size] !== undefined) {
        if (product.size_stocks[size] < quantity) {
            throw new ApiError(`Size "${size}" của "${product.name}" không đủ hàng`, 400);
        }
    }

    const itemPrice = product.final_price || product.price;
    total += itemPrice * quantity;

    // 🔥 Lấy filename ảnh
// 🔥 Lấy filename ảnh (Lấy đúng trường từ database)
    const filename = product.image_url || product.image || product.thumb || (product.images && product.images[0]) || "";
    
    // 🔥 Convert thành FULL URL CHUẨN XÁC
    const baseUrl = process.env.BASE_URL || "http://192.168.1.100:8080";
    let imageUrl = "";

    if (filename.startsWith("http")) {
      imageUrl = filename; // Nếu là link web thì giữ nguyên
    } else if (filename) {
      imageUrl = `${baseUrl}/uploads/${filename}`; // Nếu là tên file cục bộ thì mới nối thêm upload/
    }

    // 🔴 THÊM DÒNG LOG NÀY ĐỂ BẮT TẬN TAY KẺ GÂY LỖI:
    console.log(`[DEBUG ẢNH] Sản phẩm: ${product.name} | Gốc: '${filename}' ---> Sẽ lưu vào đơn: '${imageUrl}'`);

normalizedItems.push({
  productId: product._id,
  name: product.name,
  image: imageUrl,
  size: String(size),
  qty: quantity,
  price: itemPrice
});

    // --- 🔥 TRỪ KHO (Giữ hàng) ---
    // SỬA: Bỏ dòng soldCount ở đây đi
    let updateQuery = {
      $inc: { stock: -quantity } 
    };

    if (size && product.size_stocks && product.size_stocks[size] !== undefined) {
       updateQuery.$inc[`size_stocks.${size}`] = -quantity;
    }

    await Product.findByIdAndUpdate(product._id, updateQuery);
  }

  // 4. Lưu đơn hàng
  const newOrder = new Order({
    userId,
    items: normalizedItems,
    total,
    name, phone, address, note,
    paymentMethod: paymentMethod.toLowerCase(),
    status: "pending"
  });

  const savedOrder = await newOrder.save();

  // 5. Xóa giỏ hàng
  await Cart.findOneAndUpdate({ user: userId }, { $set: { items: [] } });

  console.log("✅ Tạo đơn thành công ID:", savedOrder._id);
  return savedOrder;
}

/**
 * 2. TẠO URL VNPAY
 */
async function createVnpayPayment(userId, payload) {
  const order = await create(userId, payload);

  process.env.TZ = 'Asia/Ho_Chi_Minh';
  const date = new Date();
  const createDate = moment(date).format('YYYYMMDDHHmmss');
  
  const ipAddr = '127.0.0.1';
  const tmnCode = process.env.VNP_TMN_CODE;
  const secretKey = process.env.VNP_HASH_SECRET;
  const vnpUrl = process.env.VNP_URL;
  const returnUrl = process.env.VNP_RETURN_URL;

  let vnp_Params = {};
  vnp_Params['vnp_Version'] = '2.1.0';
  vnp_Params['vnp_Command'] = 'pay';
  vnp_Params['vnp_TmnCode'] = tmnCode;
  vnp_Params['vnp_Locale'] = 'vn';
  vnp_Params['vnp_CurrCode'] = 'VND';
  vnp_Params['vnp_TxnRef'] = order._id.toString();
  vnp_Params['vnp_OrderInfo'] = 'Thanh toan don hang ' + order._id;
  vnp_Params['vnp_OrderType'] = 'other';
  vnp_Params['vnp_Amount'] = order.total * 100;
  vnp_Params['vnp_ReturnUrl'] = returnUrl;
  vnp_Params['vnp_IpAddr'] = ipAddr;
  vnp_Params['vnp_CreateDate'] = createDate;

  vnp_Params = sortObject(vnp_Params);

  const signData = qs.stringify(vnp_Params, { encode: false });
  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");
  vnp_Params['vnp_SecureHash'] = signed;

  return vnpUrl + '?' + qs.stringify(vnp_Params, { encode: false });
}

/**
 * 3. XỬ LÝ VNPAY RETURN
 */
async function vnpayReturn(query) {
  let vnp_Params = query;
  const secureHash = vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];

  vnp_Params = sortObject(vnp_Params);
  const secretKey = process.env.VNP_HASH_SECRET;
  const signData = qs.stringify(vnp_Params, { encode: false });
  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");

  if (secureHash === signed) {
    const orderId = vnp_Params['vnp_TxnRef'];
    const responseCode = vnp_Params['vnp_ResponseCode'];

    if (responseCode === "00") {
      // ✅ VNPAY thành công -> Update Confirmed -> Cộng SoldCount
      const order = await Order.findByIdAndUpdate(orderId, { 
        status: "confirmed", 
        paymentMethod: "vnpay" 
      }, { new: true });
      
      if (order) await increaseSoldCount(order); // 🔥 CỘNG SỐ LƯỢNG ĐÃ BÁN

      return { code: "00", message: "Success" };
    } 
    
    // Thất bại -> Hủy đơn & Chỉ hoàn kho (vì chưa cộng soldCount)
    const order = await Order.findByIdAndUpdate(orderId, { status: "cancelled" });
    if (order) await restoreStockOnly(order); 
    
    return { code: responseCode, message: "Fail" };
  } else {
    return { code: "97", message: "Checksum failed" };
  }
}

/**
 * 4. ADMIN CẬP NHẬT TRẠNG THÁI
 * 🔥 Logic quan trọng nằm ở đây
 */
async function updateStatus(id, status) {
  const allowed = ["pending", "confirmed", "shipping", "done", "cancelled"];
  if (!allowed.includes(status)) throw new ApiError("Invalid status", 400);
  
  const oldOrder = await Order.findById(id);
  if (!oldOrder) throw new ApiError("Order not found", 404);

  // Cập nhật trạng thái mới
  const newOrder = await Order.findByIdAndUpdate(id, { status }, { new: true });

  // --- LOGIC XỬ LÝ KHI CHUYỂN TRẠNG THÁI ---

  // 1. Nếu Admin bấm "CONFIRMED" (từ trạng thái pending)
  // => Lúc này mới cộng số lượng đã bán
  if (oldOrder.status === 'pending' && status === 'confirmed') {
      await increaseSoldCount(newOrder);
  }

  // 2. Nếu Admin bấm "CANCELLED" (Hủy đơn)
  if (status === 'cancelled') {
      await restoreStockOnly(newOrder); // Luôn phải trả hàng vào kho
      
      // Nếu đơn cũ ĐÃ confirm/shipping/done rồi mà giờ hủy 
      // -> Nghĩa là đã cộng soldCount rồi -> Phải trừ đi
      if (['confirmed', 'shipping', 'done'].includes(oldOrder.status)) {
          await decreaseSoldCount(newOrder);
      }
  }
  
 const orderWithImage = await attachImages([newOrder]);
  return orderWithImage[0];
}

// --- Helper Functions ---

// 🔥 1. Hàm cộng số lượng đã bán (Chỉ gọi khi Confirmed)
async function increaseSoldCount(order) {
    for(const item of order.items) {
        await Product.findByIdAndUpdate(item.productId, {
            $inc: { soldCount: item.qty } 
        });
    }
}

// 🔥 2. Hàm trừ số lượng đã bán (Gọi khi hủy đơn đã confirm)
async function decreaseSoldCount(order) {
    for(const item of order.items) {
        await Product.findByIdAndUpdate(item.productId, {
            $inc: { soldCount: -item.qty } 
        });
    }
}

// 🔥 3. Hàm hoàn kho (Chỉ trả lại Stock, không đụng vào soldCount)
async function restoreStockOnly(order) {
  for (const item of order.items) {
    let updateQuery = { $inc: { stock: item.qty } };

    if (item.size) {
      updateQuery.$inc[`size_stocks.${item.size}`] = item.qty;
    }

    await Product.findByIdAndUpdate(item.productId, updateQuery);
  }
} 

// --- Các hàm cơ bản khác ---
// 🔥 GẮN ẢNH CHO ĐƠN CŨ
async function attachImages(orders) {
  const baseUrl = process.env.BASE_URL || "http://192.168.1.100:8080";

  // ✅ THÊM DÒNG NÀY: Ép Mongoose Document về Object thuần để cho phép sửa đổi dữ liệu
  const parsedOrders = orders.map(order => 
    order.toObject ? order.toObject() : order
  );

  // Lưu ý: Đổi chữ 'orders' thành 'parsedOrders' ở vòng lặp
  for (const order of parsedOrders) {
    for (const item of order.items) {
      if (item.image && item.image.startsWith("http")) continue;

      const product = await Product.findById(item.productId);
      if (product) {
        const filename = product.image_url || product.image || product.thumb || (product.images && product.images[0]) || "";

        if (filename.startsWith("http")) {
          item.image = filename;
        } else if (filename) {
          item.image = `${baseUrl}/uploads/${filename}`;
        } else {
          item.image = "";
        }
      }
    }
  }

  // ✅ SỬA DÒNG NÀY: Trả về mảng đã được ép kiểu
  return parsedOrders; 
}
async function myOrders(userId) {
  const orders = await Order.find({ userId }).sort({ createdAt: -1 });

  return await attachImages(orders);
}

async function listAll() {
  const orders = await Order.find().sort({ createdAt: -1 });

  return await attachImages(orders);
}

function sortObject(obj) {
  let sorted = {};
  let str = [];
  let key;
  for (key in obj){
    if (obj.hasOwnProperty(key)) str.push(encodeURIComponent(key));
  }
  str.sort();
  for (key = 0; key < str.length; key++) {
      sorted[str[key]] = encodeURIComponent(obj[decodeURIComponent(str[key])]).replace(/%20/g, "+");
  }
  return sorted;
}

module.exports = {
  create,
  createVnpayPayment,
  vnpayReturn,
  myOrders,
  listAll,
  updateStatus
};