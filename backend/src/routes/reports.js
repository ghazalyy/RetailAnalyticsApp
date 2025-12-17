const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const ExcelJS = require('exceljs');
const prisma = new PrismaClient();

router.get('/monthly', async (req, res) => {
    try {
        const sales = await prisma.sale.findMany({
            orderBy: { orderDate: 'desc' }
        });

        const workbook = new ExcelJS.Workbook();
        const sheet = workbook.addWorksheet('Penjualan Bulanan');

        sheet.columns = [
            { header: 'Order ID', key: 'orderId', width: 20 },
            { header: 'Tanggal', key: 'orderDate', width: 15 },
            { header: 'Produk', key: 'category', width: 20 },
            { header: 'Sales (Rp)', key: 'sales', width: 15 },
            { header: 'Profit (Rp)', key: 'profit', width: 15 },
        ];

        sales.forEach(s => {
            sheet.addRow({
                orderId: s.orderId,
                orderDate: s.orderDate,
                category: s.category,
                sales: parseFloat(s.sales),
                profit: parseFloat(s.profit)
            });
        });

        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename=laporan_penjualan.xlsx');

        await workbook.xlsx.write(res);
        res.end();
    } catch (error) {
        res.status(500).json({ error: "Gagal generate excel" });
    }
});

module.exports = router;