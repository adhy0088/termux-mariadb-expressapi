#!/data/data/com.termux/files/usr/bin/bash

echo "--- Menginisialisasi MariaDB untuk Termux ---"

# 1. Update dan Install
pkg update && pkg upgrade -y
pkg install mariadb -y

# 2. Inisialisasi folder data jika belum ada
if [ ! -d "$PREFIX/var/lib/mysql" ]; then
    echo "[*] Menginisialisasi folder data database..."
    mysql_install_db
else
    echo "[*] Folder data sudah ada, melewati inisialisasi."
fi

# 3. Membersihkan socket lama jika ada (mencegah error 111)
rm -rf $PREFIX/var/run/mysqld
mkdir -p $PREFIX/var/run/mysqld
rm -f $PREFIX/var/run/mysqld/mysqld.sock

# 4. Menjalankan MariaDB Safe di latar belakang
echo "[*] Menjalankan MariaDB Server..."
mysqld_safe --datadir=$PREFIX/var/lib/mysql > /dev/null 2>&1 &

# Tunggu sebentar agar server siap
sleep 5

# 5. Membuat Database awal
echo "[*] Membuat database farmasi_db..."
mysql -u $(whoami) -e "CREATE DATABASE IF NOT EXISTS farmasi_db;"

echo "--- Setup MariaDB Selesai ---"
echo "Gunakan perintah 'mysql' untuk masuk ke konsol."
