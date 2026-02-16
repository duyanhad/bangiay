const express = require('express');
const router = express.Router();

const { requireAuth } = require('../middlewares/auth.middleware');
const ctrl = require('../controllers/order.controller');

router.post('/', requireAuth, ctrl.create);
router.post('/vnpay', requireAuth, ctrl.createVnpayPayment);
router.get('/vnpay-return', ctrl.vnpayReturn);
router.get('/my-orders', requireAuth, ctrl.myOrders);
module.exports = router;
