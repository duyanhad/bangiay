const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");

// Cấu hình nơi lưu file và tên file
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/"); // Lưu vào thư mục uploads ở gốc dự án
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({ storage: storage });

// API nhận file từ app (Tối đa 5 ảnh)
router.post("/", upload.array("images", 5), (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ ok: false, message: "Không tìm thấy file" });
    }
    // Trả về mảng đường dẫn URL ảnh
    const fileUrls = req.files.map(file => `/uploads/${file.filename}`);
    res.json({ ok: true, data: fileUrls });
  } catch (error) {
    res.status(500).json({ ok: false, message: error.message });
  }
});

module.exports = router;