const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

router.get('/', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const search = req.query.search || ""; 
        const skip = (page - 1) * limit;

        const whereClause = search ? {
            OR: [
                { name: { contains: search } },
                { id: { contains: search } }
            ]
        } : {};

        const [products, totalCount] = await prisma.$transaction([
            prisma.product.findMany({
                where: whereClause, 
                skip: skip,
                take: limit,
                orderBy: { name: 'asc' }
            }),
            prisma.product.count({ where: whereClause })
        ]);

        res.json({
            success: true,
            page: page,
            limit: limit,
            totalPages: Math.ceil(totalCount / limit),
            totalItems: totalCount,
            data: products
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Gagal mengambil data produk" });
    }
});

module.exports = router;