const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

router.post('/', async (req, res) => {
    try {
        const { productId, quantity, totalParam } = req.body;
        const newSale = await prisma.sale.create({
            data: {
                orderId: `TRX-${Date.now()}`, 
                orderDate: new Date(),
                customerId: "WALK-IN",
                segment: "Consumer",
                region: "Local",
                productId: productId,
                category: "Retail",
                sales: totalParam, 
                quantity: quantity,
                profit: totalParam * 0.2 
            }
        });

        res.json({ success: true, message: "Transaksi Berhasil!", data: newSale });

    } catch (error) {
        console.error("Error creating order:", error);
        res.status(500).json({ error: "Gagal memproses transaksi" });
    }
});

module.exports = router;