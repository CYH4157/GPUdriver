#!/bin/bash
set -e

echo "========== Docker + NVIDIA GPU 安裝與驅動修復開始 =========="

echo "[1/7] 安裝 Docker CE..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[2/7] 啟用 Docker 並加入 docker 群組..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

echo "[3/7] 修復 NVIDIA Container Toolkit APT 來源..."
LIST_FILE="/etc/apt/sources.list.d/nvidia-container.list"
distribution="ubuntu22.04"

if [ -f "$LIST_FILE" ] && grep -q "<!doctype" "$LIST_FILE"; then
    echo "⚠️ 偵測到錯誤 HTML source，刪除後重建"
    sudo rm -f "$LIST_FILE"
fi

if [ ! -f "$LIST_FILE" ]; then
    curl -s -L https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list | \
      sudo tee "$LIST_FILE"
    curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | \
      sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/nvidia-container.gpg
fi

echo "[4/7] 安裝 nvidia-docker2..."
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

echo "[5/7] 安裝當前 kernel 對應的 headers..."
sudo apt install -y linux-headers-$(uname -r)

echo "[6/7] 修復 DKMS 模組..."
sudo dkms autoinstall

echo "[7/7] 驗證 GPU 是否可於 Docker 中使用（可能尚未載入模組）..."
if ! nvidia-smi; then
  echo "⚠️ nvidia-smi 尚無法啟動，可能需要重新開機載入驅動模組"
else
  echo " nvidia-smi successful!"
fi

read -p "🔁 是否立即重新開機以載入 GPU 驅動？ [Y/n] " ans
case "$ans" in
  [yY][eE][sS]|[yY]|"")
    echo "正在重新開機..."
    sudo reboot
    ;;
  *)
    echo "請稍後手動執行 sudo reboot"
    ;;
esac
