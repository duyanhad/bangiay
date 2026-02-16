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
  console.log("--- DEBUG: Bắt đầu tạo đơn hàng ---");
  console.log("Dữ liệu nhận được:", JSON.stringify(payload, null, 2));

  // 1. Lấy dữ liệu (Hỗ trợ nhiều cách đặt tên biến từ App Flutter)
  const items = payload.items;
  const name = payload.name || payload.fullName || payload.receiverName;
  const phone = payload.phone || payload.phoneNumber || payload.phone_number;
  const address = payload.address || payload.shippingAddress;
  const paymentMethod = payload.paymentMethod || "cod";
  const note = payload.note || "";

  // 2. Kiểm tra danh sách sản phẩm
  if (!Array.isArray(items) || items.length === 0) {
    throw new ApiError("Danh sách sản phẩm không được trống", 400);
  }

  // 3. KIỂM TRA THÔNG TIN KHÁCH HÀNG (Sửa lỗi undefined ở đây)
  if (!name || !phone || !address) {
    console.log("LỖI THIẾU THÔNG TIN:", { name, phone, address });
    throw new ApiError("Vui lòng nhập đầy đủ Họ tên, SĐT và Địa chỉ giao hàng", 400);
  }

  let total = 0;
  const normalized = [];

  for (const it of items) {
    const { productId, size, qty } = it;
    
    // Tìm sản phẩm trong DB để lấy giá và ảnh thực tế (tránh khách hàng sửa giá từ client)
    const p = await Product.findById(productId);
    if (!p) throw new ApiError(`Sản phẩm ID ${productId} không tồn tại`, 404);

    const itemPrice = p.final_price || p.price;
    total += itemPrice * qty;

    // Lưu vào mảng items của đơn hàng theo đúng OrderItemSchema
    normalized.push({
      productId: p._id,
      name: p.name,
      image: p.thumb || (p.images && p.images[0]) || "", 
      size: String(size),
      qty: Number(qty),
      price: itemPrice
    });
  }

  // 4. Tạo đơn hàng với đầy đủ thông tin từ payload
  const newOrder = new Order({
    userId,
    items: normalized,
    total,
    name,    // Lưu tên khách
    phone,   // Lưu SĐT
    address, // Lưu địa chỉ
    note,    // Lưu ghi chú
    paymentMethod: paymentMethod.toLowerCase(),
    status: "pending"
  });

  const savedOrder = await newOrder.save();
  console.log("--- DEBUG: Đã lưu đơn hàng thành công ID:", savedOrder._id);
  return savedOrder;
}

/**
 * 2. TẠO THANH TOÁN VNPAY
 */
async function createVnpayPayment(userId, payload) {
  console.log("--- DEBUG: Bắt đầu quy trình VNPAY ---");
  
  // Bước A: Tạo đơn hàng vào DB trước (Trạng thái pending)
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
  vnp_Params['vnp_Amount'] = order.total * 100; // VNPAY nhân 100
  vnp_Params['vnp_ReturnUrl'] = returnUrl;
  vnp_Params['vnp_IpAddr'] = '127.0.0.1';
  vnp_Params['vnp_CreateDate'] = createDate;

  vnp_Params = sortObject(vnp_Params);

  const signData = qs.stringify(vnp_Params, { encode: false });
  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");
  vnp_Params['vnp_SecureHash'] = signed;

  const finalUrl = vnpUrl + '?' + qs.stringify(vnp_Params, { encode: false });
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
    // Thanh toán thất bại -> Hủy đơn
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