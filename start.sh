#!/bin/bash
echo "========================================"
echo "[WAN22-GGUF-5B] WORKER v1.4"
echo "========================================"

# Aguardar volume
echo "[WAN22-GGUF-5B] Aguardando volume..."
for i in {1..30}; do
    if [ -d "/runpod-volume/wan22_gguf_5b_models" ]; then
        echo "[WAN22-GGUF-5B] Volume encontrado!"
        break
    fi
    echo "  Tentativa $i/30..."
    sleep 2
done

# Verificar e listar arquivos
echo ""
echo "[WAN22-GGUF-5B] Arquivos no volume:"
ls -laR /runpod-volume/wan22_gguf_5b_models/ 2>/dev/null || echo "  Volume vazio ou nao existe"

# Criar symlinks ANTES de iniciar ComfyUI
echo ""
echo "[WAN22-GGUF-5B] Criando symlinks..."

# Garantir diretorios existem
mkdir -p /comfyui/models/diffusion_models
mkdir -p /comfyui/models/vae
mkdir -p /comfyui/models/text_encoders
mkdir -p /comfyui/models/clip_vision

# GGUF model -> diffusion_models
if [ -d "/runpod-volume/wan22_gguf_5b_models/unet" ]; then
    for f in /runpod-volume/wan22_gguf_5b_models/unet/*.gguf; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "  Linking diffusion_models/$fname"
            ln -sf "$f" "/comfyui/models/diffusion_models/$fname"
        fi
    done
fi

# VAE -> vae
if [ -d "/runpod-volume/wan22_gguf_5b_models/vae" ]; then
    for f in /runpod-volume/wan22_gguf_5b_models/vae/*.safetensors; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "  Linking vae/$fname"
            ln -sf "$f" "/comfyui/models/vae/$fname"
        fi
    done
fi

# Text Encoders -> text_encoders
if [ -d "/runpod-volume/wan22_gguf_5b_models/text_encoders" ]; then
    for f in /runpod-volume/wan22_gguf_5b_models/text_encoders/*.safetensors; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "  Linking text_encoders/$fname"
            ln -sf "$f" "/comfyui/models/text_encoders/$fname"
        fi
    done
fi

# CLIP Vision -> clip_vision
if [ -d "/runpod-volume/wan22_gguf_5b_models/clip_vision" ]; then
    for f in /runpod-volume/wan22_gguf_5b_models/clip_vision/*.safetensors; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            echo "  Linking clip_vision/$fname"
            ln -sf "$f" "/comfyui/models/clip_vision/$fname"
        fi
    done
fi

# Verificar symlinks criados
echo ""
echo "[WAN22-GGUF-5B] Verificando symlinks:"
echo "diffusion_models:"
ls -la /comfyui/models/diffusion_models/
echo ""
echo "vae:"
ls -la /comfyui/models/vae/
echo ""
echo "text_encoders:"
ls -la /comfyui/models/text_encoders/

# Iniciar ComfyUI
echo ""
echo "[WAN22-GGUF-5B] Iniciando ComfyUI..."
cd /comfyui
python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --disable-auto-launch \
    --disable-metadata &

# Aguardar
sleep 30

# Handler
echo "[WAN22-GGUF-5B] Iniciando handler..."
cd /
exec python -u /handler.py
