#!/data/data/com.termux/files/usr/bin/bash

# --- KONFIGURASI ---
# Ganti dengan URL Deployment Web App Apps Script Anda
GAS_URL="https://script.google.com/macros/s/XXXXX/exec"
DB_NAME="farmasi_db"
DB_USER=$(whoami)

echo "--- Memulai Proses Seeding Data dari Apps Script ---"

# 1. Pastikan jq terinstal
if ! command -v jq &> /dev/null; then
    echo "[*] Menginstal jq untuk pemrosesan JSON..."
    pkg install jq -y
fi

# 2. Membuat Tabel (Jika belum ada)
echo "[*] Membuat skema tabel items dan transactions..."
mysql -u $DB_USER -D $DB_NAME <<EOF
CREATE TABLE IF NOT EXISTS items (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255),
    unit VARCHAR(50),
    optimumStock INT DEFAULT 0,
    category VARCHAR(100),
    rak VARCHAR(100),
    category_nomenklatur VARCHAR(100),
    flags VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME,
    transactionId VARCHAR(100),
    type VARCHAR(50),
    source VARCHAR(255),
    itemId VARCHAR(50),
    itemName VARCHAR(255),
    quantity DECIMAL(15, 2),
    batchNo VARCHAR(100),
    expiryDate DATE,
    unit VARCHAR(50),
    userId VARCHAR(100),
    notes TEXT,
    fakturNo VARCHAR(100),
    supplier VARCHAR(255),
    budgetSource VARCHAR(100),
    price DECIMAL(15, 2),
    FOREIGN KEY (itemId) REFERENCES items(id)
);
EOF

# 3. Mengambil dan Memasukkan Data Items
echo "[*] Mengambil data items dari Google Sheets..."
ITEMS_JSON=$(curl -L "$GAS_URL?action=getItems")

echo "$ITEMS_JSON" | jq -c '.[]' | while read row; do
    ID=$(echo $row | jq -r '.id')
    NAME=$(echo $row | jq -r '.name')
    UNIT=$(echo $row | jq -r '.unit')
    STOCK=$(echo $row | jq -r '.optimumStock // 0')
    CAT=$(echo $row | jq -r '.category // "Umum"')
    RAK=$(echo $row | jq -r '.rak // ""')
    NOMEN=$(echo $row | jq -r '.category_nomenklatur // ""')
    FLAGS=$(echo $row | jq -r '.flags // ""')

    mysql -u $DB_USER -D $DB_NAME -e \
    "INSERT IGNORE INTO items (id, name, unit, optimumStock, category, rak, category_nomenklatur, flags) VALUES ('$ID', '$NAME', '$UNIT', $STOCK, '$CAT', '$RAK', '$NOMEN', '$FLAGS');"
    ON DUPLICATE KEY UPDATE rak=VALUES(rak), category_nomenklatur=VALUES(category_nomenklatur), flags=VALUES(flags);"
done

# 4. Mengambil dan Memasukkan Data Transaksi
echo "[*] Mengambil data transaksi dari Google Sheets..."
TRANS_JSON=$(curl -L "$GAS_URL?action=getTransactions")

echo "$TRANS_JSON" | jq -c '.[]' | while read row; do
    TS=$(echo $row | jq -r '.timestamp')
    TID=$(echo $row | jq -r '.transactionId')
    TYPE=$(echo $row | jq -r '.type')
    ITEMID=$(echo $row | jq -r '.itemId')
    QTY=$(echo $row | jq -r '.quantity // 0')
    PRICE=$(echo $row | jq -r '.price // 0')
    
    # Menangani format tanggal agar kompatibel dengan MariaDB
    # Kita ambil kolom sesuai urutan di script.gs 
    mysql -u $DB_USER -D $DB_NAME -e \
    "INSERT INTO transactions (timestamp, transactionId, type, itemId, quantity, price, batchNo, expiryDate, budgetSource) 
     VALUES ('$TS', '$TID', '$TYPE', '$ITEMID', $QTY, $PRICE, 
     '$(echo $row | jq -r '.batchNo // ""')', 
     '$(echo $row | jq -r '.expiryDate // "0000-00-00"')', 
     '$(echo $row | jq -r '.budgetSource // "Lain-lain"')');"
done

echo "--- Seeding Selesai! Data Anda telah bermigrasi ke MariaDB ---"