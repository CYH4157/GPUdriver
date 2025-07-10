#!/bin/bash
set -e

echo "========== CUDA Toolkit 安裝腳本開始 =========="

echo "[1/6] 更新系統與必要工具..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget curl gnupg lsb-release build-essential

echo "[2/6] 檢查是否已有 NVIDIA 驅動 (nvidia-smi)..."
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ 尚未安裝驅動！請先安裝 550.78 以上版本再執行本腳本。"
    exit 1
fi
nvidia-smi

echo "[3/6] 加入 NVIDIA 官方 APT Repository..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update

echo "[4/6] 安裝 CUDA Toolkit（最新版，非驅動）..."
sudo apt install nvidia-cuda-toolkit

echo "[5/6] 設定 CUDA 環境變數..."
echo 'export PATH=/usr/local/cuda/bin:$PATH' | sudo tee /etc/profile.d/cuda.sh
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' | sudo tee -a /etc/profile.d/cuda.sh
source /etc/profile.d/cuda.sh

echo "[6/6] 驗證 CUDA Toolkit 安裝..."
echo "→ nvcc 版本："
nvcc --version || echo "⚠️ 未找到 nvcc！"
echo "→ 驅動檢查："
nvidia-smi

echo "✅ CUDA Toolkit 安裝完成！可以使用 GPU 進行開發與訓練。"
echo "========== CUDA Toolkit 安裝腳本結束 =========="
