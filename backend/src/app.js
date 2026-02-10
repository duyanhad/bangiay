const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const rateLimit = require("express-rate-limit");

const routes = require("./routes");
const { notFound, errorHandler } = require("./middlewares/error.middleware");

const app = express();

// Security + performance (nhẹ nhưng chuẩn)
app.use(helmet());
app.use(compression());
app.use(express.json({ limit: "1mb" }));

// CORS whitelist (nếu không set thì allow all)
const origins = (process.env.CORS_ORIGINS || "").split(",").map(s => s.trim()).filter(Boolean);
app.use(cors({
  origin: origins.length ? origins : true,
  credentials: false
}));

// Rate-limit cho auth để chống spam
app.use("/api/v1/auth", rateLimit({
  windowMs: 60 * 1000,
  max: 30
}));

app.get("/", (req, res) => res.json({ ok: true, data: "Shoe Shop API" }));

app.use("/api/v1", routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
