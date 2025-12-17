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
        res.status(500).json({ error: "Gagal mengambil data" });
    }
});

router.post('/', async (req, res) => {
    try {
        const { name, category, price, stock } = req.body;
        const id = `PROD-${Date.now()}`; 
        
        const newProduct = await prisma.product.create({
            data: { 
                id, 
                name, 
                category, 
                subCategory: "General", 
                price: parseFloat(price), 
                stock: parseInt(stock) 
            }
        });
        res.json({ success: true, data: newProduct });
    } catch (error) {
        res.status(500).json({ error: "Gagal tambah produk" });
    }
});

router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, category, price, stock } = req.body;

        const updatedProduct = await prisma.product.update({
            where: { id },
            data: { 
                name, 
                category, 
                price: parseFloat(price), 
                stock: parseInt(stock) 
            }
        });
        res.json({ success: true, data: updatedProduct });
    } catch (error) {
        res.status(500).json({ error: "Gagal update produk" });
    }
});

router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.product.delete({ where: { id } });
        res.json({ success: true, message: "Produk dihapus" });
    } catch (error) {
        res.status(500).json({ error: "Gagal hapus produk" });
    }
});

module.exports = router;