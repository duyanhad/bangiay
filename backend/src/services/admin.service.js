const Product = require("../models/product.model");
const Order = require("../models/order.model");
const User = require("../models/user.model");
const Category = require("../models/category.model");
const { ApiError } = require("../utils/apiError");
const orderService = require("./order.service");
// ============================================================
// --- 1. DASHBOARD & THỐNG KÊ (ĐÃ SỬA ĐỂ HIỆN LIST TRÊN APP) ---
// ============================================================

exports.getDashboardStats = async () => {
  // Thực hiện song song các query để tối ưu tốc độ
  const [
    userCount,
    productCount,
    orderCount,
    revenueAgg,
    stockAgg,
    orderStatusAgg // 🔵 THÊM: Query gom nhóm đếm trạng thái đơn hàng
  ] = await Promise.all([
    User.countDocuments({ role: "user" }),
    Product.countDocuments(),
    Order.countDocuments(),
    // Tính tổng doanh thu (chỉ đơn đã hoàn thành)
    Order.aggregate([
      { $match: { status: "done" } },
      { $group: { _id: null, revenue: { $sum: "$total" } } }
    ]),
    // Tính tổng tồn kho
    Product.aggregate([
      { $group: { _id: null, stock: { $sum: "$stock" } } }
    ]),
    // Gom nhóm và đếm số lượng từng trạng thái đơn hàng
    Order.aggregate([
      { $group: { _id: "$status", count: { $sum: 1 } } }
    ])
  ]);

  // Bóc tách dữ liệu trạng thái đơn hàng an toàn
  let pendingOrders = 0, confirmedOrders = 0, shippingOrders = 0, completedOrders = 0, cancelledOrders = 0;
  
  if (orderStatusAgg && orderStatusAgg.length > 0) {
    orderStatusAgg.forEach(item => {
      if (item._id === 'pending') pendingOrders = item.count;
      if (item._id === 'confirmed') confirmedOrders = item.count;
      if (item._id === 'shipping') shippingOrders = item.count;
      if (item._id === 'done') completedOrders = item.count;
      if (item._id === 'cancelled') cancelledOrders = item.count;
    });
  }

  return {
    userCount,
    productCount,
    orderCount,
    revenue: revenueAgg[0]?.revenue || 0,
    totalStock: stockAgg[0]?.stock || 0,
    // Trả về cho model Flutter
    pendingOrders,
    confirmedOrders,
    shippingOrders,
    completedOrders,
    cancelledOrders
  };
};

// --- CÁC HÀM THỐNG KÊ KHÁC (GIỮ NGUYÊN) ---

// API riêng lẻ lấy low stock (nếu web admin cần dùng riêng)
exports.getLowStock = async () => {
  const baseUrl = process.env.BASE_URL || "http://localhost:8080";
  
  const products = await Product.find({ stock: { $lte: 5 } })
    .sort({ stock: 1 }) 
    .limit(5)
    .select("name images image_url price stock category");
  
  // Gắn full URL cho images
  return products.map(doc => {
    const obj = doc.toObject();
    if (obj.images && Array.isArray(obj.images)) {
      obj.images = obj.images.map(img => {
        if (img && !img.startsWith('http')) {
          return `${baseUrl}/uploads/${img}`;
        }
        return img;
      });
    }
    return obj;
  });
};

// API riêng lẻ lấy top selling (nếu web admin cần dùng riêng)
exports.getTopSelling = async () => {
  const baseUrl = process.env.BASE_URL || "http://localhost:8080";
  
  const topSelling = await Order.aggregate([
    // 1. Chỉ lọc các đơn hàng đã giao thành công
    { $match: { status: "done" } },
    
    // 2. Tách mảng items trong đơn hàng thành từng phần tử riêng để dễ đếm
    { $unwind: "$items" },
    
    // 3. Gom nhóm theo productId và cộng dồn số lượng bán (qty)
    { 
      $group: { 
        _id: "$items.productId", 
        totalSold: { $sum: "$items.qty" },
        // Tính thêm doanh thu mang lại từ sản phẩm này (Tùy chọn)
        revenueFromProduct: { $sum: { $multiply: ["$items.qty", "$items.price"] } }
      } 
    },
    
    // 4. Sắp xếp theo số lượng bán giảm dần
    { $sort: { totalSold: -1 } },
    
    // 5. Lấy Top 10 sản phẩm
    { $limit: 10 },
    
    // 6. Join với bảng Product để lấy thông tin ảnh, tên,... trả về cho Flutter
    {
      $lookup: {
        from: "products", // Lưu ý: Tên collection trong MongoDB thường có chữ "s"
        localField: "_id",
        foreignField: "_id",
        as: "productInfo"
      }
    },
    
    // 7. Giải nén mảng productInfo và gom dữ liệu lại thành 1 object chuẩn
    { $unwind: "$productInfo" },
    {
      $replaceRoot: { 
        newRoot: { 
          $mergeObjects: [
            "$productInfo", 
            { totalSold: "$totalSold", revenueFromProduct: "$revenueFromProduct" }
          ] 
        } 
      }
    }
  ]);
  
  // Gắn full URL cho images
  return topSelling.map(doc => {
    if (doc.images && Array.isArray(doc.images)) {
      doc.images = doc.images.map(img => {
        if (img && !img.startsWith('http')) {
          return `${baseUrl}/uploads/${img}`;
        }
        return img;
      });
    }
    return doc;
  });
};

// Biểu đồ doanh thu: dùng định nghĩa duy nhất ở phía dưới file.

// ============================================================
// --- 2. QUẢN LÝ USER (GIỮ NGUYÊN) ---
// ============================================================

exports.getAllUsers = async (page = 1, limit = 10, search = "") => {
  const query = { role: "user" }; 
  if (search) query.email = { $regex: search, $options: "i" };

  const skip = (page - 1) * limit;
  const [users, total] = await Promise.all([
    User.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit).select("-password"),
    User.countDocuments(query)
  ]);
  
  return { users, total, page, totalPages: Math.ceil(total / limit) };
};

exports.toggleUserLock = async (userId) => {
  const user = await User.findById(userId);
  if (!user) throw new ApiError("User not found", 404);
  if (user.role === "admin") throw new ApiError("Cannot lock admin", 400);

  user.isLocked = !user.isLocked; 
  return await user.save();
};

exports.deleteUser = async (userId) => {
  const user = await User.findById(userId);
  if (user && user.role === "admin") throw new ApiError("Cannot delete admin", 400);
  return await User.findByIdAndDelete(userId);
};

// ============================================================
// --- 3. QUẢN LÝ DANH MỤC (GIỮ NGUYÊN) ---
// ============================================================

// ============================================================
// --- 3. QUẢN LÝ DANH MỤC (FIXED PRO VERSION)
// ============================================================

exports.createCategory = async ({ name, image, description }) => {
  if (!name) {
    throw new ApiError("Category name required", 400);
  }

  const existing = await Category.findOne({ name: name.toLowerCase() });
  if (existing) {
    throw new ApiError("Category already exists", 400);
  }

  return await Category.create({
    name,
    image,
    description,
  });
};

exports.getAllCategories = async () => {
  return await Category.find().sort({ createdAt: -1 });
};

exports.updateCategory = async (id, data) => {
  const updated = await Category.findByIdAndUpdate(
    id,
    data,
    { new: true }
  );

  if (!updated) {
    throw new ApiError("Category not found", 404);
  }

  return updated;
};

exports.deleteCategory = async (id) => {
  // 🔥 Không cho xóa nếu còn sản phẩm
  const productExists = await Product.findOne({ category: id });
  if (productExists) {
    throw new ApiError(
      "Cannot delete category that still has products",
      400
    );
  }

  const deleted = await Category.findByIdAndDelete(id);

  if (!deleted) {
    throw new ApiError("Category not found", 404);
  }

  return deleted;
};

// ============================================================
// --- 4. QUẢN LÝ ĐƠN HÀNG (GIỮ NGUYÊN) ---
// ============================================================

async function attachAdminImages(orders) {
  const baseUrl = process.env.BASE_URL || "http://192.168.1.100:8080";
  const parsedOrders = orders.map(order => order.toObject ? order.toObject() : order);

  for (const order of parsedOrders) {
    for (const item of order.items) {
      if (item.image && item.image.startsWith("http")) continue;
      const product = await Product.findById(item.productId);
      if (product) {
        const filename = product.image_url || product.image || product.thumb || (product.images && product.images[0]) || "";
        if (filename.startsWith("http")) item.image = filename;
        else if (filename) item.image = `${baseUrl}/uploads/${filename}`;
        else item.image = "";
      }
    }
  }
  return parsedOrders;
}

exports.getAllOrders = async (page = 1, limit = 20, status) => {
  const query = {};
  if (status && status !== "all") query.status = status;

  const skip = (page - 1) * limit;
  const [orders, total] = await Promise.all([
    Order.find(query)
      .populate("userId", "name email phone address") 
      .sort({ createdAt: -1 })
      .skip(skip)   // ✅ Bật lại skip
      .limit(limit),// ✅ Bật lại limit
    Order.countDocuments(query)
  ]);

  const ordersWithImages = await attachAdminImages(orders);
  return { orders: ordersWithImages, total, page, totalPages: Math.ceil(total / limit) };
};

exports.updateOrderStatus = async (orderId, status) => {
  // ✅ FIX QUAN TRỌNG NHẤT: Trỏ sang hàm update xịn xò bên order.service
  // Để tự động xử lý Trừ kho, Cộng lượt bán và Gắn ảnh!
  return await orderService.updateStatus(orderId, status);
};
exports.getRevenueChart = async (type = "day") => {
  const TZ = "Asia/Ho_Chi_Minh";
  const now = new Date();

  const pad2 = (n) => String(n).padStart(2, "0");
  const cloneDate = (d) => new Date(d.getTime());

  const toDayKey = (d) => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
  const toDayLabel = (d) => `${pad2(d.getDate())}-${pad2(d.getMonth() + 1)}`;

  const toMonthKey = (d) => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}`;
  const toMonthLabel = (d) => `${pad2(d.getMonth() + 1)}/${d.getFullYear()}`;

  const toYearKey = (d) => `${d.getFullYear()}`;
  const toYearLabel = (d) => `${d.getFullYear()}`;

  let startDate;
  let groupFormat;
  const buckets = [];

  if (type === "year") {
    startDate = new Date(now.getFullYear() - 4, 0, 1, 0, 0, 0, 0);
    groupFormat = "%Y";

    for (let y = now.getFullYear() - 4; y <= now.getFullYear(); y++) {
      const d = new Date(y, 0, 1);
      buckets.push({ key: toYearKey(d), label: toYearLabel(d) });
    }
  } else if (type === "month") {
    startDate = new Date(now.getFullYear(), now.getMonth() - 11, 1, 0, 0, 0, 0);
    groupFormat = "%Y-%m";

    for (let i = 0; i < 12; i++) {
      const d = new Date(startDate.getFullYear(), startDate.getMonth() + i, 1);
      buckets.push({ key: toMonthKey(d), label: toMonthLabel(d) });
    }
  } else {
    // day: 31 ngày gần nhất (bao gồm hôm nay)
    const start = cloneDate(now);
    start.setHours(0, 0, 0, 0);
    start.setDate(start.getDate() - 30);
    startDate = start;
    groupFormat = "%Y-%m-%d";

    for (let i = 0; i < 31; i++) {
      const d = cloneDate(startDate);
      d.setDate(startDate.getDate() + i);
      buckets.push({ key: toDayKey(d), label: toDayLabel(d) });
    }
  }

  const data = await Order.aggregate([
    {
      // Dữ liệu doanh thu thực: chỉ lấy đơn đã hoàn thành (done) trong khoảng thời gian chọn
      $match: {
        status: "done",
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: {
            format: groupFormat,
            date: "$createdAt",
            timezone: TZ,
          },
        },
        revenue: { $sum: { $ifNull: ["$total", 0] } },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const revenueMap = new Map(
    data.map((item) => [item._id, Number(item.revenue) || 0])
  );

  return buckets.map((bucket) => ({
    label: bucket.label,
    revenue: revenueMap.get(bucket.key) || 0,
  }));
};
exports.getOrderDetails = async (orderId) => {
  const order = await Order.findById(orderId).populate("userId", "name email phone address");
  if (!order) throw new ApiError("Order not found", 404);
  
  // ✅ FIX: Gắn ảnh khi Admin bấm vào xem chi tiết
  const orderWithImage = await attachAdminImages([order]);
  return orderWithImage[0];
};
// ============================================================
// --- 5. QUẢN LÝ SẢN PHẨM ADMIN ---
// ============================================================

exports.getAllProductsAdmin = async () => {
  return await Product.find()
    .populate("category", "name")
    .sort({ createdAt: -1 });
};