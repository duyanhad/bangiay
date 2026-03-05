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
  return await Product.find({ stock: { $lte: 5 } })
    .sort({ stock: 1 }) 
    .limit(5)
    .select("name images price stock category");
};

// API riêng lẻ lấy top selling (nếu web admin cần dùng riêng)
exports.getTopSelling = async () => {
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
  
  return topSelling;
};

// Biểu đồ doanh thu
exports.getRevenueChart = async (type = "day") => {
  let dateFormat;
  if (type === "month") dateFormat = "%Y-%m";      
  else if (type === "year") dateFormat = "%Y";     
  else dateFormat = "%Y-%m-%d";                    

  // Lấy dữ liệu 12 tháng gần nhất
  const matchDate = new Date();
  matchDate.setFullYear(matchDate.getFullYear() - 1);

  const stats = await Order.aggregate([
    { 
      $match: { 
        status: { $in: ["confirmed", "shipping", "done"] },
        createdAt: { $gte: matchDate } 
      } 
    },
    {
      $group: {
        _id: { $dateToString: { format: dateFormat, date: "$createdAt" } },
        revenue: { $sum: "$total" },
        count: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  return stats;
};

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
exports.getRevenueChart = async (type = 'week') => {
  let dateFilter = new Date();
  let groupId = {};

  // Xác định khoảng thời gian và cách gom nhóm (group)
  if (type === 'week') {
    dateFilter.setDate(dateFilter.getDate() - 7); // 7 ngày qua
    groupId = { $dateToString: { format: "%d-%m", date: "$createdAt", timezone: "Asia/Ho_Chi_Minh" } };
  } else if (type === 'month') {
    dateFilter.setDate(dateFilter.getDate() - 30); // 30 ngày qua
    groupId = { $dateToString: { format: "%d-%m", date: "$createdAt", timezone: "Asia/Ho_Chi_Minh" } };
  } else if (type === 'year') {
    dateFilter.setMonth(dateFilter.getMonth() - 12); // 12 tháng qua
    groupId = { $dateToString: { format: "%m/%Y", date: "$createdAt", timezone: "Asia/Ho_Chi_Minh" } };
  }

  const data = await Order.aggregate([
    // 1. Chỉ lấy đơn hoàn thành và trong khoảng thời gian đã chọn
    { $match: { status: "done", createdAt: { $gte: dateFilter } } },
    
    // 2. Gom nhóm theo Ngày hoặc Tháng và tính tổng tiền
    { 
      $group: { 
        _id: groupId, 
        revenue: { $sum: "$total" } 
      } 
    },
    
    // 3. Sắp xếp theo thời gian (từ cũ tới mới)
    { $sort: { _id: 1 } } 
  ]);

  // Trả về mảng dễ đọc cho Flutter: [{ label: "15-10", revenue: 500000 }, ...]
  return data.map(item => ({
    label: item._id,
    revenue: item.revenue
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