const Product = require("../models/product.model");
const Order = require("../models/order.model");
const User = require("../models/user.model");
const Category = require("../models/category.model");
const { ApiError } = require("../utils/apiError");

// --- 1. DASHBOARD & THỐNG KÊ ---

exports.getDashboardStats = async () => {
  // Thực hiện song song các query đếm để tối ưu hiệu năng
  const [userCount, productCount, orderCount, revenueAgg, stockAgg] = await Promise.all([
    User.countDocuments({ role: "user" }),
    Product.countDocuments(),
    Order.countDocuments(),
    // Tính tổng doanh thu (chỉ đơn đã xác nhận/thành công)
    Order.aggregate([
      { $match: { status: { $in: ["confirmed", "shipping", "done"] } } }, 
      { $group: { _id: null, revenue: { $sum: "$total" } } }
    ]),
    // ✅ Tính tổng tồn kho (Total Stock) - Cần cái này cho Flutter
    Product.aggregate([
      { $group: { _id: null, totalStock: { $sum: "$stock" } } }
    ])
  ]);

  return {
    userCount,
    // ✅ Đổi tên biến cho khớp với Flutter Model (AdminStats)
    productCount: productCount, 
    orderCount: orderCount,     
    revenue: revenueAgg[0]?.revenue || 0, 
    totalStock: stockAgg[0]?.totalStock || 0 
  };
};

// ✅ THÊM HÀM NÀY (Vì Controller đang gọi nó)
exports.getLowStock = async () => {
  // Lấy 5 sản phẩm có tồn kho <= 5, sắp xếp tăng dần theo stock
  return await Product.find({ stock: { $lte: 5 } })
    .sort({ stock: 1 }) 
    .limit(5)
    .select("name images price stock category");
};

// Biểu đồ doanh thu (Chart)
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

// Top sản phẩm bán chạy
exports.getTopSelling = async () => {
  return await Product.find()
    .sort({ soldCount: -1 })
    .limit(5)
    .select("name images price soldCount category");
};

// --- 2. QUẢN LÝ USER ---

exports.getAllUsers = async (page = 1, limit = 10, search = "") => {
  const query = { role: "user" }; // Chỉ lấy user thường, không lấy admin
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

// --- 3. QUẢN LÝ DANH MỤC (CATEGORY) ---

exports.createCategory = async ({ name, image }) => {
  if (!name) throw new ApiError("Category name required", 400);
  return Category.create({ name, image });
};

exports.getAllCategories = async () => {
  return Category.find().sort({ createdAt: -1 });
};

exports.deleteCategory = async (id) => {
  return Category.findByIdAndDelete(id);
};

// --- 4. QUẢN LÝ ĐƠN HÀNG (ORDER) ---

exports.getAllOrders = async (page = 1, limit = 10, status) => {
  const query = {};
  if (status && status !== "all") query.status = status;

  const skip = (page - 1) * limit;
  const [orders, total] = await Promise.all([
    Order.find(query)
      .populate("userId", "name email phone address") 
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Order.countDocuments(query)
  ]);

  return { orders, total, page, totalPages: Math.ceil(total / limit) };
};

exports.updateOrderStatus = async (orderId, status) => {
  const allowed = ["pending", "confirmed", "shipping", "done", "cancelled"];
  if (!allowed.includes(status)) throw new ApiError("Invalid status", 400);

  const order = await Order.findByIdAndUpdate(orderId, { status }, { new: true });
  if (!order) throw new ApiError("Order not found", 404);
  return order;
};

exports.getOrderDetails = async (orderId) => {
  const order = await Order.findById(orderId).populate("userId", "name email phone address");
  if (!order) throw new ApiError("Order not found", 404);
  return order;
};