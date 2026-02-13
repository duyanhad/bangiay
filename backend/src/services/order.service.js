const { ApiError } = require("../utils/apiError");
const Order = require("../models/order.model");
const Product = require("../models/product.model");

const qs = require("qs");
const crypto = require("crypto");
const moment = require("moment");

/**
 * 1. TẠO ĐƠN HÀNG (Logic chuẩn cho cả COD và VNPAY)
 */
async function create(userId, payload) {
  console.log("--- DEBUG: Bắt đầu create order ---");
  console.log("Payload nhận được:", JSON.stringify(payload, null, 2));

  const items = payload?.items;
  if (!Array.isArray(items) || items.length === 0) {
    console.log("LỖI: Danh sách items trống");
    throw new ApiError("Items required", 400);
  }

  let total = 0;
  const normalized = [];

  for (const it of items) {
    const { productId, size, qty } = it;
    console.log(`Đang check: ProductID=${productId}, Size=${size}, Qty=${qty}`);

    const p = await Product.findById(productId);
    if (!p) {
      console.log(`LỖI: Không tìm thấy sản phẩm ID ${productId}`);
      throw new ApiError("Product not found", 404);
    }

    // Ép size về chuỗi để so sánh chính xác với mảng ["38", "39"...]
    const sizeStr = size ? size.toString() : "";
    console.log(`Size gửi lên: "${sizeStr}" (Type: ${typeof sizeStr})`);
    console.log(`Sizes hiện có trong DB:`, p.sizes);

    // KIỂM TRA SIZE
    if (!p.sizes || !Array.isArray(p.sizes) || !p.sizes.includes(sizeStr)) {
      console.log(`LỖI: Size "${sizeStr}" không tồn tại trong danh sách của sản phẩm`);
      throw new ApiError(`Size ${sizeStr} not available`, 400);
    }

    // KIỂM TRA KHO
    const stock = (p.size_stocks && p.size_stocks[sizeStr] !== undefined) 
                  ? p.size_stocks[sizeStr] 
                  : 0;
    console.log(`Tồn kho hiện tại của size ${sizeStr}: ${stock}`);
                  
    if (stock < Number(qty)) {
      console.log(`LỖI: Hết hàng. Cần ${qty}, chỉ còn ${stock}`);
      throw new ApiError("Out of stock", 400);
    }

    total += p.price * Number(qty);

    normalized.push({
      productId: p._id,
      name: p.name,
      price: p.price,
      qty: Number(qty),
      size: sizeStr,
      image: p.images?.[0] || ""
    });

    // Cập nhật kho
    p.size_stocks[sizeStr] -= Number(qty);
    p.markModified('size_stocks'); 
    await p.save();
  }

  const finalTotal = payload.total || total;
  console.log(`--- Tổng tiền đơn hàng: ${finalTotal} ---`);

  return await Order.create({
    userId,
    items: normalized,
    total: finalTotal,
    paymentMethod: payload.paymentMethod || "cod",
    shippingInfo: payload.shippingInfo,
    status: "pending"
  });
}

/**
 * 2. TẠO THANH TOÁN VNPAY
 */
async function createVnpayPayment(userId, payload) {
  console.log("--- DEBUG: Bắt đầu tạo link VNPAY ---");
  // Gọi hàm create để kiểm tra kho và tạo đơn trước
  const order = await create(userId, payload);

  process.env.TZ = 'Asia/Ho_Chi_Minh';
  const date = new Date();
  const createDate = moment(date).format('YYYYMMDDHHmmss');
  
  const tmnCode = process.env.VNP_TMN_CODE;
  const secretKey = process.env.VNP_HASH_SECRET;
  const vnpUrl = process.env.VNP_URL;
  const returnUrl = process.env.VNP_RETURN_URL;

  const vnp_TxnRef = order._id.toString();

  let vnp_Params = {};
  vnp_Params['vnp_Version'] = '2.1.0';
  vnp_Params['vnp_Command'] = 'pay';
  vnp_Params['vnp_TmnCode'] = tmnCode;
  vnp_Params['vnp_Locale'] = 'vn';
  vnp_Params['vnp_CurrCode'] = 'VND';
  vnp_Params['vnp_TxnRef'] = vnp_TxnRef;
  vnp_Params['vnp_OrderInfo'] = 'Thanh toan don hang: ' + vnp_TxnRef;
  vnp_Params['vnp_OrderType'] = 'other';
  vnp_Params['vnp_Amount'] = order.total * 100; 
  vnp_Params['vnp_ReturnUrl'] = returnUrl;
  vnp_Params['vnp_IpAddr'] = '127.0.0.1';
  vnp_Params['vnp_CreateDate'] = createDate;

  vnp_Params = sortObject(vnp_Params);

  const signData = qs.stringify(vnp_Params, { encode: false });
  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");
  vnp_Params['vnp_SecureHash'] = signed;

  const finalUrl = vnpUrl + '?' + qs.stringify(vnp_Params, { encode: false });
  console.log("--- DEBUG: Link VNPAY đã tạo xong ---");
  return finalUrl;
}

/**
 * 3. XỬ LÝ VNPAY RETURN
 */
async function vnpayReturn(query) {
  const vnp_Params = { ...query };
  const secureHash = vnp_Params['vnp_SecureHash'];

  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];

  const sortedParams = sortObject(vnp_Params);
  const secretKey = process.env.VNP_HASH_SECRET;
  const signData = qs.stringify(sortedParams, { encode: false });
  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");

  if (secureHash === signed) {
    const orderId = vnp_Params['vnp_TxnRef'];
    const responseCode = vnp_Params['vnp_ResponseCode'];

    if (responseCode === "00") {
      await Order.findByIdAndUpdate(orderId, { status: "confirmed", paymentMethod: "vnpay" });
      return { status: "00", message: "Success" };
    }
    await Order.findByIdAndUpdate(orderId, { status: "cancelled" });
    return { status: responseCode, message: "Fail" };
  } else {
    return { status: '97', message: "Fail checksum" };
  }
}

async function myOrders(userId) {
  return await Order.find({ userId }).sort({ createdAt: -1 });
}

async function listAll() {
  return await Order.find().sort({ createdAt: -1 });
}

async function updateStatus(id, status) {
  const allowed = ["pending", "confirmed", "shipping", "done", "cancelled"];
  if (!allowed.includes(status)) throw new ApiError("Invalid status", 400);
  return await Order.findByIdAndUpdate(id, { status }, { new: true });
}

function sortObject(obj) {
  let sorted = {};
  let keys = Object.keys(obj).sort();
  for (let key of keys) {
    sorted[key] = encodeURIComponent(obj[key]).replace(/%20/g, "+");
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