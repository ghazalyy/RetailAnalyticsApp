const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const prisma = new PrismaClient();

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = 'uploads/';
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

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

router.post('/', upload.single('image'), async (req, res) => {
    try {
        const { name, category, price, stock } = req.body;
        const id = `PROD-${Date.now()}`; 
        
        const imagePath = req.file ? `/uploads/${req.file.filename}` : "";
        
        const newProduct = await prisma.product.create({
            data: { 
                id, 
                name, 
                category, 
                subCategory: "General", 
                price: parseFloat(price), 
                stock: parseInt(stock),
                image: imagePath 
            }
        });
        res.json({ success: true, data: newProduct });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Gagal tambah produk" });
    }
});

router.put('/:id', upload.single('image'), async (req, res) => {
    try {
        const { id } = req.params;
        const { name, category, price, stock } = req.body;

        const dataToUpdate = {
            name, 
            category, 
            price: parseFloat(price), 
            stock: parseInt(stock) 
        };

        if (req.file) {
            const oldProduct = await prisma.product.findUnique({ where: { id } });
            if (oldProduct && oldProduct.image) {
                const oldPath = path.join(__dirname, '../../', oldProduct.image);
                if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
            }

            dataToUpdate.image = `/uploads/${req.file.filename}`;
        }

        const updatedProduct = await prisma.product.update({
            where: { id },
            data: dataToUpdate
        });

        res.json({ success: true, data: updatedProduct });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Gagal update produk" });
    }
});

router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const product = await prisma.product.findUnique({ where: { id } });

        if (product && product.image) {
            const filePath = path.join(__dirname, '../../', product.image);
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
            }
        }

        await prisma.product.delete({ where: { id } });
        res.json({ success: true, message: "Produk dihapus" });
    } catch (error) {
        res.status(500).json({ error: "Gagal hapus produk" });
    }
});

module.exports = router;