const mongoose = require("mongoose");

const CategorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Category name is required"],
      unique: true, // ✅ Đã tự tạo index
      trim: true,
      lowercase: true,
      minlength: 2,
      maxlength: 100,
    },

    description: {
      type: String,
      default: "",
      trim: true,
      maxlength: 500,
    },

    image: {
      type: String,
      default: "",
      trim: true,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

// ❌ XÓA CategorySchema.index({ name: 1 });
// unique: true đã đủ rồi

// ✅ Bắt lỗi duplicate key đẹp hơn (không crash)
CategorySchema.post("save", function (error, doc, next) {
  if (error && error.code === 11000) {
    next(new Error("Category name already exists"));
  } else {
    next(error);
  }
});

module.exports = mongoose.model("Category", CategorySchema);