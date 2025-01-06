#!/bin/bash

# Auto Installer OpenVPN + API
# Script by YourName
# Usage: bash auto_vpn.sh

# Fungsi untuk memeriksa apakah perintah berhasil dijalankan
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Update sistem
echo "Mengupdate sistem..."
apt update && apt upgrade -y
check_command "Gagal mengupdate sistem."

# Instal dependensi
echo "Menginstal dependensi..."
apt install -y openvpn easy-rsa python3 python3-pip iptables jq
check_command "Gagal menginstal dependensi."

# Instal Flask menggunakan pip3
echo "Menginstal Flask..."
pip3 install flask
check_command "Gagal menginstal Flask."

# Instal vnstat
echo "Menginstal vnstat..."
apt install -y vnstat
check_command "Gagal menginstal vnstat."

# Setup OpenVPN
echo "Menginstal OpenVPN..."
wget https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh -O /tmp/openvpn-install.sh
chmod +x /tmp/openvpn-install.sh
export AUTO_INSTALL=y
export APPROVE_INSTALL=y
export APPROVE_IP=y
export IPV6_SUPPORT=n
export PORT_CHOICE=1
export PROTOCOL_CHOICE=1
export DNS=1
export COMPRESSION_ENABLED=n
export CUSTOMIZE_ENC=n
export CLIENT=client
export PASS=1
/tmp/openvpn-install.sh
check_command "Gagal menginstal OpenVPN."

# Hapus database lama jika ada
if [ -d "/var/lib/vnstat/tun0" ]; then
    echo "Menghapus database vnstat lama untuk tun0..."
    rm -rf /var/lib/vnstat/tun0
fi

# Buat database baru untuk tun0
echo "Membuat database vnstat untuk tun0..."
vnstat -i tun0 --add
check_command "Gagal membuat database vnstat untuk tun0."

# Mulai dan aktifkan vnstat
systemctl restart vnstat
systemctl enable vnstat
check_command "Gagal memulai vnstat."

# Setup cron job untuk memeriksa penggunaan bandwidth
echo "Menyiapkan cron job..."
cat <<EOF > /etc/cron.d/vpn-bandwidth
0 0 * * * root /usr/bin/vnstat --delete --force -i tun0 && /usr/bin/vnstat -i tun0 --add
EOF

# Setup API dengan Flask
echo "Menyiapkan API..."
mkdir -p /etc/openvpn/api
cat <<EOF > /etc/openvpn/api/api.py
from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

# Database sederhana untuk menyimpan informasi user
USERS_DB = {}

@app.route('/create_user', methods=['POST'])
def create_user():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    monthly_limit = data.get('monthly_limit', '100GB')  # Default 100GB

    if not username or not password:
        return jsonify({"error": "Username dan password diperlukan"}), 400

    if username in USERS_DB:
        return jsonify({"error": "User sudah ada"}), 400

    # Buat user OpenVPN
    subprocess.run(["/root/openvpn-install.sh", "--client", username], input=f"{password}\n{password}\n", text=True)
    check_command("Gagal membuat user OpenVPN.")

    # Berikan IP unik
    ip_pool = ["10.8.0." + str(i) for i in range(101, 200)]
    used_ips = [user['ip'] for user in USERS_DB.values()]
    available_ip = next((ip for ip in ip_pool if ip not in used_ips), None)

    if not available_ip:
        return jsonify({"error": "Tidak ada IP tersedia"}), 500

    # Simpan informasi user
    USERS_DB[username] = {
        "password": password,
        "ip": available_ip,
        "monthly_limit": monthly_limit,
        "usage": 0
    }

    return jsonify({"message": "User berhasil dibuat", "user": USERS_DB[username]})

@app.route('/check_usage', methods=['GET'])
def check_usage():
    username = request.args.get('username')
    if not username or username not in USERS_DB:
        return jsonify({"error": "User tidak ditemukan"}), 404

    return jsonify({"username": username, "usage": USERS_DB[username]['usage']})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Setup systemd service untuk API
echo "Menyiapkan service API..."
cat <<EOF > /etc/systemd/system/vpn-api.service
[Unit]
Description=OpenVPN Management API
After=network.target

[Service]
User=root
WorkingDirectory=/etc/openvpn/api
ExecStart=/usr/bin/python3 /etc/openvpn/api/api.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Mulai dan aktifkan service API
systemctl daemon-reload
systemctl start vpn-api
systemctl enable vpn-api
check_command "Gagal menyiapkan service API."

# Selesai
echo "Instalasi selesai!"
echo "API berjalan di http://$(curl -s ifconfig.me):5000"
echo "Gunakan endpoint /create_user untuk membuat user baru."
echo "Contoh: curl -X POST http://$(curl -s ifconfig.me):5000/create_user -H 'Content-Type: application/json' -d '{\"username\":\"user1\", \"password\":\"pass123\"}'"
