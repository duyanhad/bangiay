const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const rateLimit = require("express-rate-limit");

const routes = require("./routes");
const { notFound, errorHandler } = require("./middlewares/error.middleware");
const path = require("path"); 
const app = express();

app.use(helmet());
app.use(compression());
app.use(express.json({ limit: "1mb" }));

// ✅ CORS phải đặt TRƯỚC routes
app.use(cors({
  origin: true, // hoặc '*' (nhưng true linh hoạt hơn)
  methods: ["GET","POST","PUT","PATCH","DELETE","OPTIONS"],
  allowedHeaders: ["Content-Type","Authorization"],
}));
app.options(/.*/, cors()),// ✅ cho preflight

app.use("/api/v1/auth", rateLimit({
  windowMs: 60 * 1000,
  max: 30
}));

app.get("/", (req, res) => res.json({ ok: true, data: "Shoe Shop API" }));
// ⭐ MỞ PUBLIC FOLDER UPLOADS
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));
app.use("/api/v1", routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
