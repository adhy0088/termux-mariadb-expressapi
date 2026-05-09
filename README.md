# termux-mariadb-expressapi
ini adalah langkah Migrasi dari Google Sheets ke MariaDB akan memberikan performa yang jauh lebih stabil, integritas data yang lebih kuat, dan skalabilitas yang lebih baik untuk sistem inventaris


# install
```Bash
pkg install php php-fpm nginx mariadb composer wget zip
```
```Bash
mariadb
```
buat sesi baru termux
```Bash
mariadb -u root
```
```Bash
show databases;
```
```Bash
use mysql;
```
```Bash
set password for root@localhost password('admin123');;
flush privileges;
exit;
```


Cara Penggunaan:
Simpan kedua file di direktori home Termux Anda.

Beri izin eksekusi:
```Bash
chmod +x mariadb.sh api-express.sh
```

Jalankan database terlebih dahulu:
```Bash
./mariadb.sh
```
Buka session/tab baru di Termux, lalu jalankan API:

```Bash
./api-express.sh
```

# seeder.sh
Untuk melengkapi proses migrasi ini, 
kita akan membuat skrip seeder.sh 
yang berfungsi sebagai jembatan. Skrip ini akan mengambil data dari endpoint API Google Apps Script Anda (fungsi handleGetItems dan handleGetTransactions), lalu memasukkannya ke dalam tabel MariaDB di Termux.  
Skrip ini menggunakan curl untuk mengambil data dan jq untuk memproses JSON. Pastikan Anda menginstal jq terlebih dahulu dengan perintah 

```Bash
pkg install jq.
```

Cara MenjalankanBeri izin eksekusi:
```Bash
chmod +x seeder.sh
```
Jalankan skrip:
```bash
./seeder.sh
```
# Penjelasan Logika Akses Data: 
Skrip ini memanggil action=getItems dan action=getTransactions yang sudah Anda buat di doGet(e) Apps Script.  
Integritas Relasional: Tabel items diisi lebih dulu sebelum transactions karena adanya Foreign Key pada itemId.  
Penanganan Null: Menggunakan jq dengan operator // untuk memberikan nilai default (seperti 0 untuk harga atau Umum untuk kategori) agar tidak terjadi error saat insert ke MariaDB.Format SQL: Skrip menggunakan INSERT IGNORE untuk barang agar jika skrip dijalankan ulang, tidak terjadi error duplikasi pada ID barang yang sama. 
