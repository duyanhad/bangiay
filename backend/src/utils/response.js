function ok(res, data, meta) {
  return res.json({ ok: true, data, meta });
}
function fail(res, message, status = 400) {
  return res.status(status).json({ ok: false, message });
}
module.exports = { ok, fail };
