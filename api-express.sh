#!/data/data/com.termux/files/usr/bin/bash

echo "--- Menyiapkan API Express.js (Catdigi-fims) ---"

# 1. Setup Folder Proyek
mkdir -p ~/catdigi-api
cd ~/catdigi-api

# 2. Inisialisasi NPM dan Install Module
pkg install nodejs -y
npm init -y
npm install express mysql2 cors

# 3. Membuat file index.js (Logic dari script.gs)
cat <<EOT > index.js
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const dbConfig = {
  host: 'localhost',
  user: '$(whoami)',
  password: '',
  database: 'farmasi_db'
};

// GET currentStock (Logika SQL dari script.gs)
app.get('/api/stock', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute(\`
      SELECT 
        t.itemId, t.itemName, i.category, t.unit, t.budgetSource, t.price,
        SUM(CASE 
          WHEN t.type = 'Masuk' THEN t.quantity 
          WHEN t.type IN ('Keluar', 'Stok ED') THEN -t.quantity 
          ELSE 0 
        END) AS totalQty
      FROM transactions t
      LEFT JOIN items i ON t.itemId = i.id
      GROUP BY t.itemId, t.budgetSource, t.price
    \`);
    await connection.end();
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => console.log('Server berjalan di port ' + PORT));
EOT

echo "[*] Menjalankan server API..."
node index.js
