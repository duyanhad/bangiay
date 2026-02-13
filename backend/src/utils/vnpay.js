const qs = require("qs");
const crypto = require("crypto");
const moment = require("moment");
const config = require("../config/vnpay.config");

function sortObject(obj) {
  let sorted = {};
  let keys = Object.keys(obj).sort();
  for (let key of keys) {
    sorted[key] = obj[key];
  }
  return sorted;
}

exports.createPaymentUrl = (orderId, amount, ipAddr) => {
  const tmnCode = config.vnp_TmnCode;
  const secretKey = config.vnp_HashSecret;
  const vnpUrl = config.vnp_Url;
  const returnUrl = config.vnp_ReturnUrl;

  const date = moment().format("YYYYMMDDHHmmss");

  let vnp_Params = {
    vnp_Version: "2.1.0",
    vnp_Command: "pay",
    vnp_TmnCode: tmnCode,
    vnp_Locale: "vn",
    vnp_CurrCode: "VND",
    vnp_TxnRef: orderId,
    vnp_OrderInfo: "Thanh toan don hang",
    vnp_OrderType: "other",
    vnp_Amount: amount * 100,
    vnp_ReturnUrl: returnUrl,
    vnp_IpAddr: ipAddr,
    vnp_CreateDate: date,
  };

  vnp_Params = sortObject(vnp_Params);

  const signData = qs.stringify(vnp_Params, { encode: false });

  const hmac = crypto.createHmac("sha512", secretKey);
  const signed = hmac.update(signData).digest("hex");

  vnp_Params.vnp_SecureHash = signed;

  return vnpUrl + "?" + qs.stringify(vnp_Params, { encode: false });
};
