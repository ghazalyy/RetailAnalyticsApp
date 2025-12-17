const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

router.get('/', async (req, res) => {
    try {
        const aggregations = await prisma.sale.aggregate({
            _sum: {
                sales: true,
                profit: true,
            },
            _count: {
                id: true,
            }
        });

        const lowStockCount = await prisma.product.count({
            where: { stock: { lt: 10 } }
        });

        const salesByCategory = await prisma.sale.groupBy({
            by: ['category'],
            _sum: {
                sales: true
            }
        });

        const categoryData = {};
        salesByCategory.forEach(item => {
            categoryData[item.category] = Number(item._sum.sales) || 0;
        });

        const recentSales = await prisma.sale.findMany({
            take: 50,
            orderBy: { orderDate: 'desc' },
            select: { orderDate: true, sales: true }
        });

        const trendData = {};
        recentSales.forEach(sale => {
            const monthKey = sale.orderDate.toISOString().slice(0, 7);
            if (!trendData[monthKey]) trendData[monthKey] = 0;
            trendData[monthKey] += Number(sale.sales);
        });

        res.json({
            success: true,
            data: {
                generated_at: new Date(),
                kpi: {
                    total_sales: Number(aggregations._sum.sales) || 0,
                    total_profit: Number(aggregations._sum.profit) || 0,
                    total_orders: Number(aggregations._count.id) || 0
                },
                low_stock_count: Number(lowStockCount),
                pie_chart_category: categoryData,
                line_chart_trend: trendData
            }
        });

    } catch (error) {
        console.error("Dashboard Error:", error);
        res.status(500).json({ error: "Gagal memuat data dashboard" });
    }
});

module.exports = router;