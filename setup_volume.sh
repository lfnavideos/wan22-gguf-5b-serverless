#!/bin/bash
# =============================================================================
# Setup Network Volume para Wan 2.2 TI2V 5B GGUF
# Execute este script dentro de um Pod conectado ao Network Volume
# =============================================================================

echo "========================================"
echo "SETUP: Wan 2.2 TI2V 5B GGUF Models"
echo "========================================"

# Diretorio base no volume
BASE_DIR="/runpod-volume/wan22_gguf_5b_models"

# Criar estrutura de diretorios
echo "[1/5] Criando diretorios..."
mkdir -p $BASE_DIR/unet
mkdir -p $BASE_DIR/vae
mkdir -p $BASE_DIR/text_encoders
mkdir -p $BASE_DIR/clip_vision

# Download modelo GGUF (Q4_K_M - melhor balanco qualidade/velocidade)
echo ""
echo "[2/5] Baixando modelo GGUF Q4_K_M (~3.4GB)..."
wget -c -O $BASE_DIR/unet/wan2.2-ti2v-5b-Q4_K_M.gguf \
  "https://huggingface.co/QuantStack/Wan2.2-TI2V-5B-GGUF/resolve/main/wan2.2-ti2v-5b-Q4_K_M.gguf"

# Download VAE Wan 2.2
echo ""
echo "[3/5] Baixando VAE Wan 2.2 (~335MB)..."
wget -c -O $BASE_DIR/vae/wan2.2_vae.safetensors \
  "https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B/resolve/main/vae/wan2.2_vae.safetensors"

# Download Text Encoder
echo ""
echo "[4/5] Baixando Text Encoder (~4.8GB)..."
wget -c -O $BASE_DIR/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# Download CLIP Vision (backup, caso nao esteja na imagem)
echo ""
echo "[5/5] Baixando CLIP Vision (~1.1GB)..."
wget -c -O $BASE_DIR/clip_vision/clip_vision_h.safetensors \
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# Verificar downloads
echo ""
echo "========================================"
echo "VERIFICANDO ARQUIVOS"
echo "========================================"
echo ""
echo "Estrutura final:"
ls -lhR $BASE_DIR

echo ""
echo "========================================"
echo "RESUMO"
echo "========================================"
du -sh $BASE_DIR/*
echo ""
du -sh $BASE_DIR
echo ""
echo "Setup completo! Volume pronto para uso."
echo "========================================"
