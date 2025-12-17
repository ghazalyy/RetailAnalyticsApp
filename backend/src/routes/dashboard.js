const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const DATA_PATH = path.join(__dirname, '../../dashboard_summary.json');

router.get('/', async (req, res) => {
    try {
        let jsonData = {};
        if (fs.existsSync(DATA_PATH)) {
            const rawData = fs.readFileSync(DATA_PATH);
            jsonData = JSON.parse(rawData);
        }

        const lowStockCount = await prisma.product.count({
            where: {
                stock: { lt: 10 }
            }
        });

        res.json({
            success: true,
            data: {
                ...jsonData,
                low_stock_count: lowStockCount 
            }
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router;