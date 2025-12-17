const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

router.post('/', async (req, res) => {
    try {
        const { items } = req.body; 

        if (!items || items.length === 0) {
            return res.status(400).json({ error: "Keranjang kosong" });
        }

        const orderId = `TRX-${Date.now()}`;
        
        await prisma.$transaction(async (tx) => {
            for (const item of items) {
                const product = await tx.product.findUnique({
                    where: { id: item.productId }
                });

                if (!product) {
                    throw new Error(`Produk ID ${item.productId} tidak ditemukan`);
                }

                if (product.stock < item.quantity) {
                    throw new Error(`Stok ${product.name} tidak cukup! Sisa: ${product.stock}`);
                }

                await tx.product.update({
                    where: { id: item.productId },
                    data: {
                        stock: {
                            decrement: item.quantity
                        }
                    }
                });

                await tx.sale.create({
                    data: {
                        orderId: orderId,
                        orderDate: new Date(),
                        customerId: "WALK-IN",
                        segment: "Consumer",
                        region: "Local",
                        productId: item.productId,
                        category: item.category || product.category,
                        sales: item.price * item.quantity,
                        quantity: item.quantity,
                        profit: (item.price * item.quantity) * 0.2
                    }
                });
            }
        });

        res.json({ success: true, message: "Transaksi Berhasil & Stok Berkurang!" });

    } catch (error) {
        console.error("Transaction Error:", error.message);
        res.status(400).json({ error: error.message || "Gagal memproses transaksi" });
    }
});

module.exports = router;