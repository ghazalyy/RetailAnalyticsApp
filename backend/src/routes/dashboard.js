const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');

const DATA_PATH = path.join(__dirname, '../../dashboard_summary.json');

router.get('/', (req, res) => {
    try {
        if (!fs.existsSync(DATA_PATH)) {
            return res.status(404).json({ 
                error: "Data dashboard belum digenerate. Jalankan script Python ETL dulu." 
            });
        }

        const rawData = fs.readFileSync(DATA_PATH);
        const jsonData = JSON.parse(rawData);

        res.json({
            success: true,
            data: jsonData
        });

    } catch (error) {
        console.error("Error reading dashboard data:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router;