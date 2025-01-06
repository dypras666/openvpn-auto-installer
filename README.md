---

# **OpenVPN Auto Installer dengan API Manajemen User**

Proyek ini adalah script otomatis untuk menginstal OpenVPN di server Ubuntu, dilengkapi dengan API sederhana untuk manajemen user (membuat user, memeriksa penggunaan bandwidth, dll). Script ini juga menyertakan fitur pembatasan bandwidth per bulan untuk setiap user.

---

## **Fitur**
- Instalasi OpenVPN otomatis.
- Manajemen user melalui API:
  - Membuat user baru.
  - Memeriksa penggunaan bandwidth.
- Pembatasan bandwidth per bulan.
- Monitoring bandwidth menggunakan `vnstat`.
- Port forwarding untuk setiap user.

---

## **Persyaratan**
- Sistem operasi: Ubuntu 20.04 atau yang lebih baru.
- Akses root atau sudo.

---

## **Instalasi**

1. **Clone Repository**:
   ```bash
   git clone https://github.com/dypras666/openvpn-auto-installer.git
   cd openvpn-auto-installer
   ```

2. **Jalankan Script Instalasi**:
   ```bash
   sudo bash auto_vpn.sh
   ```

3. **Verifikasi Instalasi**:
   - Setelah instalasi selesai, API akan berjalan di `http://<IP_SERVER>:5000`.
   - File konfigurasi OpenVPN akan disimpan di `/root/client.ovpn`.

---

## **Penggunaan**

### **Membuat User Baru**
Gunakan endpoint `/create_user` untuk membuat user baru. Contoh:
```bash
curl -X POST http://<IP_SERVER>:5000/create_user -H "Content-Type: application/json" -d '{
  "username": "user1",
  "password": "pass123",
  "monthly_limit": "50GB"
}'
```

### **Memeriksa Penggunaan Bandwidth**
Gunakan endpoint `/check_usage` untuk memeriksa penggunaan bandwidth. Contoh:
```bash
curl http://<IP_SERVER>:5000/check_usage?username=user1
```

---

## **Dokumentasi API**

### **Base URL**
`http://<IP_SERVER>:5000`

### **Endpoint**
1. **Membuat User Baru**:
   - **URL**: `/create_user`
   - **Method**: `POST`
   - **Parameter**:
     - `username` (string): Nama user.
     - `password` (string): Password user.
     - `monthly_limit` (string, opsional): Batasan bandwidth bulanan (contoh: `100GB`). Default: `100GB`.

2. **Memeriksa Penggunaan Bandwidth**:
   - **URL**: `/check_usage`
   - **Method**: `GET`
   - **Parameter**:
     - `username` (string): Nama user.

---

## **Contoh Penggunaan**

### **Membuat User Baru**
- **Request**:
  ```bash
  curl -X POST http://192.168.1.100:5000/create_user -H "Content-Type: application/json" -d '{
    "username": "user1",
    "password": "pass123",
    "monthly_limit": "50GB"
  }'
  ```
- **Response**:
  ```json
  {
    "message": "User berhasil dibuat",
    "user": {
      "password": "pass123",
      "ip": "10.8.0.101",
      "monthly_limit": "50GB",
      "usage": 0
    }
  }
  ```

### **Memeriksa Penggunaan Bandwidth**
- **Request**:
  ```bash
  curl http://192.168.1.100:5000/check_usage?username=user1
  ```
- **Response**:
  ```json
  {
    "username": "user1",
    "usage": 1024
  }
  ```

---

## **Error Handling**
API akan mengembalikan pesan error dalam format JSON jika terjadi kesalahan. Beberapa error yang mungkin terjadi:
- `400 Bad Request`: Parameter tidak valid atau tidak lengkap.
- `404 Not Found`: User tidak ditemukan.
- `500 Internal Server Error`: Terjadi kesalahan pada server.

---

## **Kontribusi**
Jika Anda ingin berkontribusi pada proyek ini, silakan buka **Issue** atau ajukan **Pull Request**.

---

## **Lisensi**
Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---

## **Penulis**
- **Dypras** - [dypras666](https://github.com/dypras666)

--- 
